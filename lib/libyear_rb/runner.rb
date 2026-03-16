# frozen_string_literal: true

require "uri"

module LibyearRb
  class Runner
    MAX_WORKERS_PER_HOST = 10
    RATE_LIMIT = 10 # requests per second per host

    def initialize(lockfile_parser:, gem_info_fetcher_factory:, dependency_analyzer:, formatter:, logger: nil)
      @lockfile_parser = lockfile_parser
      @gem_info_fetcher_factory = gem_info_fetcher_factory
      @dependency_analyzer = dependency_analyzer
      @formatter = formatter
      @logger = logger
    end

    def run(lockfile_contents, as_of: nil)
      lockfile = @lockfile_parser.parse(lockfile_contents)

      jobs_by_host = {}
      lockfile.sources.each do |source|
        unless source.type == :gem && !source.remote.nil?
          @logger&.warn("Skipping source #{source.type}: unsupported source type or missing remote")
          next
        end

        remote_host = URI.parse(source.remote).host
        (jobs_by_host[remote_host] ||= []).concat(source.specs)
      end

      results = []
      results_mutex = Mutex.new
      threads = []
      replenishers = []

      jobs_by_host.each do |remote_host, specs|
        work_queue = Thread::SizedQueue.new(MAX_WORKERS_PER_HOST)
        token_queue = Thread::SizedQueue.new(RATE_LIMIT)

        # Pre-fill token bucket
        RATE_LIMIT.times { token_queue << :token }

        # Producer: enqueue specs then close
        threads << Thread.new do
          specs.each { |spec| work_queue << spec }
          work_queue.close
        end

        # Replenisher: push tokens at RATE_LIMIT/sec
        replenishers << Thread.new do
          loop do
            sleep(1.0 / RATE_LIMIT)
            token_queue << :token
          end
        end

        # Consumers: pop spec, acquire token, process
        [specs.size, MAX_WORKERS_PER_HOST].min.times do
          threads << Thread.new do
            fetcher = @gem_info_fetcher_factory.call
            while (spec = work_queue.pop)
              token_queue.pop # wait for rate limit token
              process_spec(fetcher, spec, remote_host, as_of, results, results_mutex)
            end
          end
        end
      end

      threads.each(&:join)
      replenishers.each(&:kill)
      @formatter.generate(results)
      results
    end

    private

    def process_spec(fetcher, spec, remote_host, as_of, results, results_mutex)
      gem_name = spec.name
      gem_version = spec.version
      versions_metadata = fetcher.gem_versions_for(gem_name, remote_host)
        .reject { |version| as_of && version.created_at > as_of }
        .sort_by(&:number)
        .reverse

      if versions_metadata.empty?
        @logger&.warn("Skipping #{gem_name}: no version metadata from #{remote_host}")
        return
      end

      result = @dependency_analyzer.calculate_dependency_freshness(gem_name, gem_version, versions_metadata)
      results_mutex.synchronize { results << result } if result
    rescue => e
      @logger&.error("Error processing #{spec.name}: #{e.message}")
    end
  end
end

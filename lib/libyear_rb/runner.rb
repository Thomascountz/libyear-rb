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
      results = []
      results_mutex = Mutex.new
      threads = []
      replenishers = []

      specs_by_host = specs_by_host(lockfile_contents)
      specs_by_host.each do |remote_host, specs|
        work_queue = Thread::Queue.new
        token_queue = Thread::SizedQueue.new(RATE_LIMIT)
        rate_limiter = -> { token_queue.pop }

        # Enqueue specs then close the work queue
        specs.each { |spec| work_queue << spec }
        work_queue.close

        # Replenisher: push tokens at RATE_LIMIT/sec
        replenishers << Thread.new do
          loop do
            sleep(1.0 / RATE_LIMIT)
            token_queue << :token
          end
        end

        # Consumers: pop spec, process
        [specs.size, MAX_WORKERS_PER_HOST].min.times do
          threads << Thread.new do
            fetcher = @gem_info_fetcher_factory.call(rate_limiter: rate_limiter)
            while (spec = work_queue.pop)
              process_spec(fetcher, spec, remote_host, as_of, results, results_mutex)
            end
          end
        end
      end

      threads.each(&:value)
      @formatter.generate(results)
      results
    rescue Exception # rubocop:disable Lint/RescueException
      threads.each { |t| t.kill unless t == Thread.current }
      raise
    ensure
      replenishers.each(&:kill)
    end

    private

    def specs_by_host(lockfile_contents)
      lockfile = @lockfile_parser.parse(lockfile_contents)
      lockfile.sources
        .reject { |source| source.type != :gem || source.remote.nil? }
        .to_h { |source|
          remote_host = URI.parse(source.remote).host
          [remote_host, source.specs.uniq(&:name)]
        }
    end

    def process_spec(fetcher, spec, remote_host, as_of, results, results_mutex)
      versions_metadata = fetcher.gem_versions_for(spec.name, remote_host)
        .reject { |version| as_of && version.created_at > as_of }
        .sort_by(&:number)
        .reverse

      if versions_metadata.empty?
        @logger&.warn("Skipping #{spec.name}: no version metadata from #{remote_host}")
        return
      end

      result = @dependency_analyzer.calculate_dependency_freshness(spec, versions_metadata)
      results_mutex.synchronize { results << result } if result
    rescue => e
      @logger&.error("Error processing #{spec.name}: #{e.message}")
    end
  end
end

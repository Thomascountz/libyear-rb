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
      threads = []
      replenishers = []

      specs_by_host = specs_by_host(lockfile_contents)
      specs_by_host.each do |remote_host, specs|
        work_queue = Thread::Queue.new
        token_queue = Thread::SizedQueue.new(RATE_LIMIT)
        rate_limiter = -> { token_queue.pop }

        specs.each { |spec| work_queue << spec }
        work_queue.close

        replenishers << Thread.new do
          loop do
            sleep(1.0 / RATE_LIMIT)
            token_queue << :token
          end
        end

        [specs.size, MAX_WORKERS_PER_HOST].min.times do
          threads << Thread.new do
            thread_results = []
            fetcher = @gem_info_fetcher_factory.call(rate_limiter: rate_limiter)
            while (spec = work_queue.pop)
              result = process_spec(fetcher, spec, remote_host, as_of)
              thread_results << result if result
            end
            thread_results
          end
        end
      end

      results = threads.flat_map(&:value)
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

    def process_spec(fetcher, spec, remote_host, as_of)
      versions_metadata = fetcher.gem_versions_for(spec.name, remote_host)
        .reject { |version| as_of && version.created_at > as_of }
        .sort_by(&:number)
        .reverse

      if versions_metadata.empty?
        @logger&.warn("Skipping #{spec.name}: no version metadata from #{remote_host}")
        return nil
      end

      @dependency_analyzer.calculate_dependency_freshness(spec, versions_metadata)
    rescue => e
      @logger&.error("Error processing #{spec.name}: #{e.message}")
      nil
    end
  end
end

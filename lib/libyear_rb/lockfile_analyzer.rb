# frozen_string_literal: true

require "uri"

module LibyearRb
  class LockfileAnalyzer
    MAX_WORKERS_PER_HOST = 10
    RATE_LIMIT = 10 # requests per second per host

    def initialize(gem_info_fetcher_factory:, dependency_analyzer:, logger: nil,
      max_workers_per_host: MAX_WORKERS_PER_HOST, rate_limit: RATE_LIMIT)
      @gem_info_fetcher_factory = gem_info_fetcher_factory
      @dependency_analyzer = dependency_analyzer
      @logger = logger
      @max_workers_per_host = max_workers_per_host
      @rate_limit = rate_limit
    end

    def analyze(lockfile, as_of: nil)
      results = []
      results_mutex = Mutex.new
      threads = []
      replenishers = []

      specs_by_host(lockfile).each do |remote_host, specs|
        work_queue = Thread::Queue.new
        token_queue = Thread::SizedQueue.new(@rate_limit)
        rate_limiter = -> { token_queue.pop }

        specs.each { |spec| work_queue << spec }
        work_queue.close

        replenishers << Thread.new do
          loop do
            sleep(1.0 / @rate_limit)
            token_queue << :token
          end
        end

        [specs.size, @max_workers_per_host].min.times do
          threads << Thread.new do
            fetcher = @gem_info_fetcher_factory.call(rate_limiter: rate_limiter)
            while (spec = work_queue.pop)
              process_spec(fetcher, spec, remote_host, as_of, results, results_mutex)
            end
          end
        end
      end

      threads.each(&:value)
      results
    rescue Exception # rubocop:disable Lint/RescueException
      threads.each { |thread| thread.kill unless thread == Thread.current }
      raise
    ensure
      replenishers.each(&:kill)
    end

    private

    def specs_by_host(lockfile)
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

# frozen_string_literal: true

require "uri"

module LibyearRb
  class LockfileAnalyzer
    MAX_WORKERS_PER_HOST = 10
    RATE_LIMIT = 10 # requests per second per host

    def initialize(gem_info_fetcher:, dependency_analyzer:, logger: nil,
      max_workers_per_host: MAX_WORKERS_PER_HOST, rate_limit: RATE_LIMIT)
      @gem_info_fetcher = gem_info_fetcher
      @dependency_analyzer = dependency_analyzer
      @logger = logger
      @max_workers_per_host = max_workers_per_host
      @rate_limit = rate_limit
    end

    def analyze(lockfile, as_of: nil)
      results = []
      results_mutex = Mutex.new
      rate_limiters = {}
      rate_limiters_mutex = Mutex.new
      threads = analyzable_sources(lockfile).flat_map do |source|
        workers_for(
          source,
          as_of: as_of,
          results: results,
          results_mutex: results_mutex,
          rate_limiters: rate_limiters,
          rate_limiters_mutex: rate_limiters_mutex
        )
      end

      threads.each(&:value)
      results
    rescue Exception # rubocop:disable Lint/RescueException
      threads&.each { |thread| thread.kill unless thread == Thread.current }
      raise
    end

    private

    def analyzable_sources(lockfile)
      lockfile.sources.select { |source| source.type == :gem && source.remote }
    end

    def workers_for(source, as_of:, results:, results_mutex:, rate_limiters:, rate_limiters_mutex:)
      specs = source.specs.uniq(&:name)
      return [] if specs.empty?

      work_queue = Thread::Queue.new
      specs.each { |spec| work_queue << spec }
      work_queue.close

      rate_limiter = rate_limiter_for(source, rate_limiters, rate_limiters_mutex)
      worker_count = [specs.size, @max_workers_per_host].min

      Array.new(worker_count) do
        Thread.new do
          while (spec = work_queue.pop)
            process_spec(
              spec,
              source: source,
              rate_limiter: rate_limiter,
              as_of: as_of,
              results: results,
              results_mutex: results_mutex
            )
          end
        end
      end
    end

    def process_spec(spec, source:, rate_limiter:, as_of:, results:, results_mutex:)
      versions_metadata = @gem_info_fetcher.gem_versions_for(
        spec.name,
        remote: source.remote,
        rate_limiter: rate_limiter
      )
        .reject { |version| as_of && version.created_at > as_of }
        .sort_by(&:number)
        .reverse

      if versions_metadata.empty?
        @logger&.warn("Skipping #{spec.name}: no version metadata from #{source.remote}")
        return
      end

      result = @dependency_analyzer.calculate_dependency_freshness(spec, versions_metadata)
      results_mutex.synchronize { results << result } if result
    rescue => e
      @logger&.error("Error processing #{spec.name}: #{e.message}")
    end

    def rate_limiter_for(source, rate_limiters, rate_limiters_mutex)
      host = URI.parse(source.remote).host

      rate_limiters_mutex.synchronize do
        rate_limiters[host] ||= FixedRateLimiter.new(rate: @rate_limit)
      end
    end

    class FixedRateLimiter
      def initialize(rate:)
        @interval = 1.0 / rate
        @mutex = Mutex.new
        @next_available_at = monotonic_time
      end

      def acquire
        delay = @mutex.synchronize do
          now = monotonic_time
          wait = [@next_available_at - now, 0].max
          @next_available_at = [@next_available_at, now].max + @interval
          wait
        end

        sleep(delay) if delay.positive?
      end

      private

      def monotonic_time
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
    end
  end
end

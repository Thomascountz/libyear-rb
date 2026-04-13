# frozen_string_literal: true

require "uri"

module LibyearRb
  class Runner
    MAX_WORKERS_PER_HOST = 10
    RATE_LIMIT = 10 # requests per second per host

    def initialize(formatter: PlaintextFormatter.new)
      @formatter = formatter
    end

    def run(lockfile_contents, as_of: nil)
      specs_by_host = parse_specs(lockfile_contents)
      threads = []
      replenishers = []

      specs_by_host.each do |host, specs|
        token_queue = Thread::SizedQueue.new(RATE_LIMIT)
        rate_limiter = -> { token_queue.pop }

        work_queue = Thread::Queue.new
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
            fetcher = GemInfoFetcher.new(host, rate_limiter: rate_limiter)
            thread_results = []
            while (spec = work_queue.pop)
              begin
                versions = fetcher.versions_for(spec.name)
                thread_results << [spec, versions]
              rescue => e
                LibyearRb.logger.error("Error fetching #{spec.name}: #{e.message}")
              end
            end
            thread_results
          end
        end
      end

      spec_versions = threads.flat_map(&:value)
      results = spec_versions.filter_map { |spec, versions| analyze(spec, versions, as_of: as_of) }
      @formatter.generate(results)
      results
    rescue Exception # rubocop:disable Lint/RescueException
      threads.each { |t| t.kill unless t == Thread.current }
      raise
    ensure
      replenishers.each(&:kill)
    end

    private

    def parse_specs(lockfile_contents)
      lockfile = LockfileParser.parse(lockfile_contents)
      lockfile.sources
        .select { |source| source.type == :gem && source.remote }
        .group_by { |source| URI.parse(source.remote).host }
        .transform_values { |sources| sources.flat_map(&:specs).uniq(&:name) }
    end

    def analyze(spec, versions, as_of:)
      filtered = versions
        .reject { |v| as_of && v.created_at > as_of }
        .sort_by(&:number)
        .reverse

      if filtered.empty?
        LibyearRb.logger.warn("Skipping #{spec.name}: no version metadata")
        return nil
      end

      DependencyAnalyzer.freshness(spec, filtered)
    rescue => e
      LibyearRb.logger.error("Error processing #{spec.name}: #{e.message}")
      nil
    end
  end
end

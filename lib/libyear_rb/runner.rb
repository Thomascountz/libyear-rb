# frozen_string_literal: true

require "uri"

module LibyearRb
  class Runner
    def initialize(lockfile_parser:, gem_info_fetcher:, dependency_analyzer:, reporter:, logger: nil)
      @lockfile_parser = lockfile_parser
      @gem_info_fetcher = gem_info_fetcher
      @dependency_analyzer = dependency_analyzer
      @reporter = reporter
      @logger = logger
    end

    def run(lockfile_contents, as_of: nil)
      specs_with_hosts = parse_specs(lockfile_contents)

      results = []
      results_mutex = Mutex.new
      threads = specs_with_hosts.map do |spec, remote_host|
        Thread.new do
          result = fetch_and_analyze(spec, remote_host, as_of: as_of)
          results_mutex.synchronize { results << result } if result
        end
      end
      join_all(threads)
      @reporter.generate(results)
      results
    end

    private

    def parse_specs(lockfile_contents)
      specs = []
      lockfile = @lockfile_parser.parse(lockfile_contents)
      lockfile.sources.each do |source|
        unless source.type == :gem && !source.remote.nil?
          @logger&.warn("Skipping source #{source.type}: unsupported source type or missing remote")
          next
        end

        remote_host = URI.parse(source.remote).host

        source.specs.each do |spec|
          specs << [spec, remote_host]
        end
      end
      specs
    end

    def fetch_and_analyze(spec, remote_host, as_of:)
      versions_metadata = @gem_info_fetcher.gem_versions_for(spec.name, remote_host)
        .reject { |version| as_of && version.created_at > as_of }
        .sort_by(&:number)
        .reverse

      if versions_metadata.empty?
        @logger&.warn("Skipping #{spec.name}: no version metadata from #{remote_host}")
        return
      end

      @dependency_analyzer.calculate_dependency_freshness(spec.name, spec.version, versions_metadata)
    end

    def join_all(threads)
      threads.each(&:join)
    rescue Exception # rubocop:disable Lint/RescueException
      threads.each { |t| t.kill unless t == Thread.current }
      raise
    end
  end
end

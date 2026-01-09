# frozen_string_literal: true

require "uri"

module LibyearRb
  class Runner
    def initialize(lockfile_parser:, gem_info_fetcher:, dependency_analyzer:, reporter:, as_of: Date.today, logger: Logger.new(IO::NULL))
      @lockfile_parser = lockfile_parser
      @gem_info_fetcher = gem_info_fetcher
      @dependency_analyzer = dependency_analyzer
      @reporter = reporter
      @as_of = as_of
      @logger = logger
    end

    def run(lockfile_contents)
      results = []
      lockfile = @lockfile_parser.parse(lockfile_contents)
      lockfile.sources.each do |source|
        unless source.type == :gem && !source.remote.nil?
          @logger.warn("Skipping source #{source.type}: unsupported source type or missing remote")
          next
        end

        remote_host = URI.parse(source.remote).host

        source.specs.each do |spec|
          gem_name = spec.name
          gem_version = spec.version
          versions_metadata = @gem_info_fetcher.gem_versions_for(gem_name, remote_host)
            .reject { |version| version.created_at > @as_of }
            .sort_by(&:number)
            .reverse

          if versions_metadata.empty?
            @logger.warn("Skipping #{gem_name}: no version metadata from #{remote_host}")
            next
          end

          result = @dependency_analyzer.calculate_dependency_freshness(gem_name, gem_version, versions_metadata)
          results << result if result
        end
      end
      @reporter.generate(results)
      results
    end
  end
end

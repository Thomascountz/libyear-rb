# frozen_string_literal: true

require "uri"

module LibyearRb
  class Runner
    def initialize(lockfile_parser:, gem_info_fetcher:, dependency_analyzer:, formatter:, logger: nil)
      @lockfile_parser = lockfile_parser
      @gem_info_fetcher = gem_info_fetcher
      @dependency_analyzer = dependency_analyzer
      @formatter = formatter
      @logger = logger
    end

    def run(lockfile_contents, as_of: nil)
      results = []
      lockfile = @lockfile_parser.parse(lockfile_contents)
      lockfile.sources.each do |source|
        unless source.type == :gem && !source.remote.nil?
          @logger&.warn("Skipping source #{source.type}: unsupported source type or missing remote")
          next
        end

        remote_host = URI.parse(source.remote).host

        source.specs.each do |spec|
          versions_metadata = @gem_info_fetcher.gem_versions_for(spec.name, remote_host)
            .reject { |version| as_of && version.created_at > as_of }
            .sort_by(&:number)
            .reverse

          if versions_metadata.empty?
            @logger&.warn("Skipping #{spec.name}: no version metadata from #{remote_host}")
            next
          end

          result = @dependency_analyzer.calculate_dependency_freshness(spec, versions_metadata)

          results << result if result
        end
      end
      @formatter.generate(results)
      results
    end
  end
end

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
      gems_to_fetch = {}
      lockfile = @lockfile_parser.parse(lockfile_contents)
      lockfile.sources.each do |source|
        unless source.type == :gem && !source.remote.nil?
          @logger&.warn("Skipping source #{source.type}: unsupported source type or missing remote")
          next
        end

        remote_host = URI.parse(source.remote).host

        source.specs.each do |spec|
          gems_to_fetch[remote_host] ||= []
          gems_to_fetch[remote_host] << spec
        end
      end

      results = []
      host_threads = []
      spec_threads = {}
      gems_to_fetch.each do |remote_host, specs|
        host_threads << Thread.new do
          spec_threads[remote_host] = []
          specs.each do |spec|
            spec_threads[remote_host] << Thread.new do
              gem_name = spec.name
              gem_version = spec.version

              versions_metadata = @gem_info_fetcher.gem_versions_for(gem_name, remote_host)
                .reject { |version| as_of && version.created_at > as_of }
                .sort_by(&:number)
                .reverse

              if versions_metadata.empty?
                @logger&.warn("Skipping #{gem_name}: no version metadata from #{remote_host}")
                next
              end

              result = @dependency_analyzer.calculate_dependency_freshness(gem_name, gem_version, versions_metadata)
              results << result if result
            end
          end
          spec_threads[remote_host].each(&:join)
        end
      end
      host_threads.each(&:join)
      @reporter.generate(results)
      results
    end
  end
end

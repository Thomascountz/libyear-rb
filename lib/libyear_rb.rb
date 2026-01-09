# frozen_string_literal: true

require_relative "libyear_rb/version"
require_relative "libyear_rb/models"
require_relative "libyear_rb/config"
require_relative "libyear_rb/lockfile_parser"
require_relative "libyear_rb/gem_info_cacher"
require_relative "libyear_rb/gem_info_fetcher"
require_relative "libyear_rb/dependency_analyzer"
require_relative "libyear_rb/reporters/reporter"
require_relative "libyear_rb/reporters/plaintext_reporter"
require_relative "libyear_rb/runner"
require_relative "libyear_rb/cli"

module LibyearRb
  class Error < StandardError; end

  def self.analyze(lockfile_contents, config: Config.new)
    lockfile_parser = LockfileParser.new
    gem_info_fetcher = GemInfoFetcher.new(use_cache: config.use_cache)
    dependency_analyzer = DependencyAnalyzer.new(logger: config.logger)
    reporter = PlaintextReporter.new

    runner = Runner.new(
      as_of: config.as_of,
      logger: config.logger,
      lockfile_parser: lockfile_parser,
      gem_info_fetcher: gem_info_fetcher,
      dependency_analyzer: dependency_analyzer,
      reporter: reporter
    )

    runner.run(lockfile_contents)
  end
end

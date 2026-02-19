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
    runner = Runner.new(
      config: config,
      lockfile_parser: LockfileParser.new,
      gem_info_fetcher: GemInfoFetcher.new(config: config),
      dependency_analyzer: DependencyAnalyzer.new(config: config),
      reporter: PlaintextReporter.new
    )

    runner.run(lockfile_contents)
  end
end

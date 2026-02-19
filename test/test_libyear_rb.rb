# frozen_string_literal: true

require_relative "test_helper"
require "stringio"

class TestLibyearRb < Minitest::Test
  def test_analyze_accepts_lockfile_contents_and_config
    config = LibyearRb::Config.new(
      as_of: Date.new(2025, 1, 1),
      use_cache: false
    )

    lockfile_contents = <<~LOCKFILE
      GEM
        remote: https://rubygems.org/
        specs:
          rake (13.0.0)

      PLATFORMS
        ruby

      DEPENDENCIES
        rake

      BUNDLED WITH
         2.6.2
    LOCKFILE

    # Stub GemInfoFetcher to avoid network calls
    fake_fetcher = Object.new
    def fake_fetcher.gem_versions_for(gem_name, remote_host)
      [
        LibyearRb::GemVersion.new(
          name: gem_name,
          number: Gem::Version.new("13.1.0"),
          created_at: Date.new(2024, 6, 1),
          prerelease?: false
        ),
        LibyearRb::GemVersion.new(
          name: gem_name,
          number: Gem::Version.new("13.0.0"),
          created_at: Date.new(2023, 1, 1),
          prerelease?: false
        )
      ]
    end

    runner = LibyearRb::Runner.new(
      logger: config.logger,
      as_of: config.as_of,
      lockfile_parser: LibyearRb::LockfileParser.new,
      gem_info_fetcher: fake_fetcher,
      dependency_analyzer: LibyearRb::DependencyAnalyzer.new(logger: config.logger),
      reporter: LibyearRb::PlaintextReporter.new(io: StringIO.new)
    )

    results = runner.run(lockfile_contents)

    assert_equal 1, results.length
    assert_equal "rake", results.first.name
    assert_equal "13.0.0", results.first.current_version
    assert_equal Gem::Version.new("13.1.0"), results.first.latest_version
  end
end

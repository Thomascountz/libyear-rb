# frozen_string_literal: true

require_relative "test_helper"

class TestLockfileAnalyzer < Minitest::Test
  class FakeGemInfoFetcher
    attr_reader :calls

    def initialize(responses: {}, errors: {})
      @responses = responses
      @errors = errors
      @calls = Queue.new
    end

    def gem_versions_for(gem_name, remote:, rate_limiter: nil)
      @calls << {gem_name: gem_name, remote: remote, rate_limiter: rate_limiter}
      raise @errors.fetch([remote, gem_name]) if @errors.key?([remote, gem_name])

      @responses.fetch([remote, gem_name], [])
    end

    def recorded_calls
      [].tap do |values|
        values << @calls.pop until @calls.empty?
      end
    end
  end

  class FakeDependencyAnalyzer
    attr_reader :inputs

    def initialize(result: nil)
      @result = result
      @inputs = Queue.new
    end

    def calculate_dependency_freshness(spec, versions_metadata)
      @inputs << {spec: spec, versions_metadata: versions_metadata}
      @result || LibyearRb::Result.new(
        name: spec.name,
        current_version: spec.version,
        current_version_release_date: versions_metadata.last.created_at,
        latest_version: versions_metadata.first.number,
        latest_version_release_date: versions_metadata.first.created_at,
        version_distance: 1,
        libyear_in_days: 10,
        is_direct: spec.direct
      )
    end

    def recorded_inputs
      [].tap do |values|
        values << @inputs.pop until @inputs.empty?
      end
    end
  end

  class FakeLogger
    attr_reader :warnings, :errors

    def initialize
      @warnings = []
      @errors = []
    end

    def warn(message)
      @warnings << message
    end

    def error(message)
      @errors << message
    end
  end

  def test_analyzes_sources_by_remote_without_collapsing_same_host_sources
    source_a = LibyearRb::Source.new(
      type: :gem,
      remote: "https://example.com/private/",
      revision: nil,
      specs: [LibyearRb::Spec.new(name: "private-one", version: "1.0.0", direct: true)],
      options: {}
    )
    source_b = LibyearRb::Source.new(
      type: :gem,
      remote: "https://example.com/other/",
      revision: nil,
      specs: [LibyearRb::Spec.new(name: "private-two", version: "2.0.0", direct: true)],
      options: {}
    )
    lockfile = LibyearRb::Lockfile.new(
      sources: [source_a, source_b],
      platforms: [],
      dependencies: [],
      ruby_version: nil,
      bundled_with: nil
    )
    fetcher = FakeGemInfoFetcher.new(
      responses: {
        ["https://example.com/private/", "private-one"] => versions("1.0.0", "1.1.0"),
        ["https://example.com/other/", "private-two"] => versions("2.0.0", "2.1.0")
      }
    )
    dependency_analyzer = FakeDependencyAnalyzer.new
    analyzer = LibyearRb::LockfileAnalyzer.new(
      gem_info_fetcher: fetcher,
      dependency_analyzer: dependency_analyzer
    )

    results = analyzer.analyze(lockfile)

    assert_equal %w[private-one private-two], results.map(&:name).sort
    assert_equal [
      "https://example.com/other/",
      "https://example.com/private/"
    ], fetcher.recorded_calls.map { |call| call[:remote] }.sort
  end

  def test_filters_versions_using_as_of_before_analyzing_dependency_freshness
    spec = LibyearRb::Spec.new(name: "rails", version: "1.0.0", direct: true)
    source = LibyearRb::Source.new(
      type: :gem,
      remote: "https://rubygems.org/",
      revision: nil,
      specs: [spec],
      options: {}
    )
    lockfile = LibyearRb::Lockfile.new(
      sources: [source],
      platforms: [],
      dependencies: [],
      ruby_version: nil,
      bundled_with: nil
    )
    fetcher = FakeGemInfoFetcher.new(
      responses: {
        ["https://rubygems.org/", "rails"] => [
          LibyearRb::GemVersion.new(name: "rails", number: Gem::Version.new("2.0.0"), created_at: Date.new(2025, 1, 1), prerelease?: false),
          LibyearRb::GemVersion.new(name: "rails", number: Gem::Version.new("1.1.0"), created_at: Date.new(2024, 1, 1), prerelease?: false),
          LibyearRb::GemVersion.new(name: "rails", number: Gem::Version.new("1.0.0"), created_at: Date.new(2023, 1, 1), prerelease?: false)
        ]
      }
    )
    dependency_analyzer = FakeDependencyAnalyzer.new
    analyzer = LibyearRb::LockfileAnalyzer.new(
      gem_info_fetcher: fetcher,
      dependency_analyzer: dependency_analyzer
    )

    analyzer.analyze(lockfile, as_of: Date.new(2024, 12, 31))

    analyzed_versions = dependency_analyzer.recorded_inputs.first.fetch(:versions_metadata)
    assert_equal %w[1.1.0 1.0.0], analyzed_versions.map { |version| version.number.to_s }
  end

  def test_logs_and_continues_when_processing_a_spec_raises
    good_spec = LibyearRb::Spec.new(name: "good", version: "1.0.0", direct: true)
    bad_spec = LibyearRb::Spec.new(name: "bad", version: "1.0.0", direct: true)
    source = LibyearRb::Source.new(
      type: :gem,
      remote: "https://rubygems.org/",
      revision: nil,
      specs: [good_spec, bad_spec],
      options: {}
    )
    lockfile = LibyearRb::Lockfile.new(
      sources: [source],
      platforms: [],
      dependencies: [],
      ruby_version: nil,
      bundled_with: nil
    )
    fetcher = FakeGemInfoFetcher.new(
      responses: {
        ["https://rubygems.org/", "good"] => versions("1.0.0", "1.1.0")
      },
      errors: {
        ["https://rubygems.org/", "bad"] => StandardError.new("boom")
      }
    )
    dependency_analyzer = FakeDependencyAnalyzer.new
    logger = FakeLogger.new
    analyzer = LibyearRb::LockfileAnalyzer.new(
      gem_info_fetcher: fetcher,
      dependency_analyzer: dependency_analyzer,
      logger: logger
    )

    results = analyzer.analyze(lockfile)

    assert_equal ["good"], results.map(&:name)
    assert_equal ["Error processing bad: boom"], logger.errors
  end

  private

  def versions(*numbers)
    numbers.each_with_index.map do |number, index|
      LibyearRb::GemVersion.new(
        name: "demo",
        number: Gem::Version.new(number),
        created_at: Date.new(2024, 1, 1) - index,
        prerelease?: false
      )
    end
  end
end

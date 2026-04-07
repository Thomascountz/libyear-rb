# frozen_string_literal: true

require_relative "test_helper"

class TestGemInfoFetcher < Minitest::Test
  SourceStub = Struct.new(:uri)

  class FakeCache
    attr_reader :calls

    def initialize
      @calls = []
    end

    def fetch(remote:, gem_name:)
      @calls << {remote: remote, gem_name: gem_name}
      yield
    end
  end

  class FakeClient
    @instances = []

    class << self
      attr_reader :instances

      def reset!
        @instances = []
      end
    end

    attr_reader :host, :username, :password

    def initialize(host:, username:, password:)
      @host = host
      @username = username
      @password = password
      self.class.instances << self
    end

    def versions(_gem_name)
      [
        {
          "number" => "1.2.3",
          "created_at" => "2024-01-01",
          "prerelease" => false
        }
      ]
    end
  end

  class FakeRateLimiter
    attr_reader :acquisitions

    def initialize
      @acquisitions = 0
    end

    def acquire
      @acquisitions += 1
    end
  end

  def setup
    FakeClient.reset!
  end

  def test_uses_exact_matching_source_configuration
    cache = FakeCache.new
    sources = [
      SourceStub.new(URI.parse("https://token@example.com/private/")),
      SourceStub.new(URI.parse("https://wrong@example.com/other/"))
    ]
    rate_limiter = FakeRateLimiter.new
    fetcher = LibyearRb::GemInfoFetcher.new(
      cache: cache,
      sources: sources,
      client_class: FakeClient
    )

    versions = fetcher.gem_versions_for("demo", remote: "https://example.com/private/", rate_limiter: rate_limiter)

    assert_equal 1, versions.length
    assert_equal 1, rate_limiter.acquisitions
    assert_equal [{remote: "https://example.com/private/", gem_name: "demo"}], cache.calls
    assert_equal ["https://example.com/private/"], FakeClient.instances.map(&:host)
    assert_equal ["token"], FakeClient.instances.map(&:username)
  end

  def test_falls_back_to_remote_when_multiple_sources_share_a_host
    cache = FakeCache.new
    sources = [
      SourceStub.new(URI.parse("https://token@example.com/private/")),
      SourceStub.new(URI.parse("https://other-token@example.com/other/"))
    ]
    fetcher = LibyearRb::GemInfoFetcher.new(
      cache: cache,
      sources: sources,
      client_class: FakeClient
    )

    fetcher.gem_versions_for("demo", remote: "https://example.com/unmatched/")

    assert_equal ["https://example.com/unmatched/"], FakeClient.instances.map(&:host)
    assert_equal [nil], FakeClient.instances.map(&:username)
  end
end

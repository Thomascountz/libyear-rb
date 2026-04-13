# frozen_string_literal: true

require "date"
require "gems"
require "rubygems"

module LibyearRb
  class GemInfoFetcher
    def initialize(remote_host, rate_limiter: -> {})
      @remote_host = remote_host
      @rate_limiter = rate_limiter
      source = Gem.sources.each_source.find { |s| s.uri.host == remote_host }
      if source
        uri = source.uri
        @client = Gems::Client.new(
          host: uri.origin + uri.request_uri,
          username: uri.user,
          password: uri.password
        )
      end
    end

    def versions_for(gem_name)
      return [] unless @client

      raw = fetch_raw(gem_name)
      parse_versions(gem_name, raw)
    end

    private

    def fetch_raw(gem_name)
      LibyearRb.cache.fetch(@remote_host, gem_name) do
        @rate_limiter.call
        Array(@client.versions(gem_name))
      rescue Gems::GemError, Gems::NotFound
        []
      end
    end

    def parse_versions(gem_name, raw_versions)
      Array(raw_versions).map do |attrs|
        GemVersion.new(
          name: gem_name,
          number: Gem::Version.new(attrs["number"]),
          created_at: Date.parse(attrs["created_at"]),
          prerelease?: attrs["prerelease"]
        )
      end
    end
  end
end

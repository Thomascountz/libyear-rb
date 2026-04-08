# frozen_string_literal: true

require "date"
require "gems"
require "rubygems"

module LibyearRb
  class GemInfoFetcher
    include GemInfoCacher

    def initialize(rate_limiter: nil)
      @gem_source_clients = {}
      @rate_limiter = rate_limiter
    end

    def gem_versions_for(gem_name, remote_host)
      client = client_for(remote_host)
      return [] unless client

      raw_versions = fetch_raw_versions(client, remote_host, gem_name)
      build_versions(gem_name, raw_versions)
    end

    private

    def fetch_raw_versions(client, remote_host, gem_name)
      with_cache(remote_host, gem_name) do
        @rate_limiter&.acquire
        client.versions(gem_name)
      rescue Gems::GemError, Gems::NotFound
        []
      end
    end

    def build_versions(gem_name, raw_versions)
      Array(raw_versions)
        .map do |attributes|
          GemVersion.new(
            name: gem_name,
            number: Gem::Version.new(attributes["number"]),
            created_at: Date.parse(attributes["created_at"]),
            prerelease?: attributes["prerelease"]
          )
        end
    end

    def client_for(remote_host)
      return @gem_source_clients[remote_host] if @gem_source_clients.key?(remote_host)

      client = nil
      source = sources.find { |gem_source| gem_source.uri.host == remote_host }

      if source
        uri = source.uri
        client = Gems::Client.new(
          host: (uri.origin + uri.request_uri),
          username: uri.user,
          password: uri.password
        )
      end

      @gem_source_clients[remote_host] = client
    end

    def sources
      @sources ||= Gem.sources.each_source.to_a
    end
  end
end

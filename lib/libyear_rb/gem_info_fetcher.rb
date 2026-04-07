# frozen_string_literal: true

require "date"
require "gems"
require "rubygems"
require "uri"

module LibyearRb
  class GemInfoFetcher
    def initialize(cache: GemInfoCacher.new, sources: Gem.sources.each_source.to_a, client_class: Gems::Client)
      @cache = cache
      @sources = sources
      @client_class = client_class
    end

    def gem_versions_for(gem_name, remote:, rate_limiter: nil)
      raw_versions = fetch_raw_versions(client_for(remote), remote, gem_name, rate_limiter)
      build_versions(gem_name, raw_versions)
    end

    private

    def fetch_raw_versions(client, remote, gem_name, rate_limiter)
      @cache.fetch(remote: remote, gem_name: gem_name) do
        rate_limiter&.acquire
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

    def client_for(remote)
      uri = configured_source_uri_for(remote) || URI.parse(remote)

      @client_class.new(
        host: (uri.origin + uri.request_uri),
        username: uri.user,
        password: uri.password
      )
    end

    def configured_source_uri_for(remote)
      remote_uri = URI.parse(remote)

      exact_match = @sources.find do |source|
        same_remote?(source.uri, remote_uri)
      end
      if exact_match
        exact_match.uri
      else
        host_matches = @sources.select { |source| source.uri.host == remote_uri.host }
        host_matches.first.uri if host_matches.one?
      end
    end

    def same_remote?(left, right)
      left.scheme == right.scheme &&
        left.host == right.host &&
        left.port == right.port &&
        normalize_path(left.path) == normalize_path(right.path)
    end

    def normalize_path(path)
      normalized = path.to_s
      normalized = "/" if normalized.empty?
      normalized.end_with?("/") ? normalized : "#{normalized}/"
    end
  end
end

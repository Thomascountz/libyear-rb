# frozen_string_literal: true

require "date"
require "gems"
require "rubygems"

module LibyearRb
  class GemInfoFetcher
    include GemInfoCacher

    RATE_LIMIT = 10 # https://guides.rubygems.org/rubygems-org-rate-limits/
    RATE_LIMIT_INTERVAL = 1.0 / RATE_LIMIT

    def initialize
      @gem_source_client_pools = {}
      @last_request_time = Hash.new { |hash, key| hash[key] = Time.now - RATE_LIMIT_INTERVAL }
    end

    def gem_versions_for(gem_name, remote_host)
      pool = pool_for(remote_host)
      client = pool.checkout
      return [] unless client

      raw_versions = fetch_raw_versions(client, remote_host, gem_name)
      build_versions(gem_name, raw_versions)
    ensure
      pool.checkin(client)
    end

    private

    def fetch_raw_versions(client, remote_host, gem_name)
      with_cache(remote_host, gem_name) do
        wait_for_rate_limit(remote_host)

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

    def pool_for(remote_host)
      @gem_source_client_pools[remote_host] ||= begin
        Pool.new(10) do
          if (uri = source_uris.fetch(remote_host))
            Gems::Client.new(
              host: (uri.origin + uri.request_uri),
              username: uri.user,
              password: uri.password
            )
          end
        end
      end
    end

    def source_uris
      @source_uris ||= Gem.sources.each_source.to_h { |s| [s.uri.host, s.uri] }
    end

    def wait_for_rate_limit(remote_host)
      now = Time.now
      elapsed = now - @last_request_time[remote_host]
      sleep(RATE_LIMIT_INTERVAL - elapsed) if elapsed < RATE_LIMIT_INTERVAL
      @last_request_time[remote_host] = Time.now
    end
  end

  class Pool
    def initialize(max_connections, &block)
      @create_connection_proc = block
      @max_connections = max_connections
      @created_count = 0
      @mutex = ::Thread::Mutex.new
      @resource = ::Thread::ConditionVariable.new
      @connections = []
    end

    def checkout
      @mutex.synchronize do
        loop do
          if @created_count > 0 && @connections.length > 0
            return @connections.pop
          end

          if @created_count < @max_connections
            @connections << @create_connection_proc.call
            @created_count += 1
          end

          @resource.wait(@mutex, 0.02)
        end
      end
    end

    def checkin(connection)
      @mutex.synchronize do
        @connections.push(connection)
        @resource.broadcast
      end
    end
  end
end

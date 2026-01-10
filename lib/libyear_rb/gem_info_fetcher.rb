# frozen_string_literal: true

require "date"
require "gems"
require "rubygems"

module LibyearRb
  class GemInfoFetcher
    include GemInfoCacher

    RATE_LIMIT = 10 # https://guides.rubygems.org/rubygems-org-rate-limits/
    RATE_LIMIT_INTERVAL = 1.0 / RATE_LIMIT
    MAX_CONNECTIONS_PER_HOST = 10

    def initialize
      @gem_source_client_pools = {}
      @rate_limit_mutexes = {}
      @last_request_time = Hash.new { |hash, key| hash[key] = Time.now - RATE_LIMIT_INTERVAL }
      @pool_mutex = Mutex.new
    end

    def gem_versions_for(gem_name, remote_host)
      pool = pool_for(remote_host)
      client = pool.checkout
      return [] unless client

      raw_versions = fetch_raw_versions(client, remote_host, gem_name)
      build_versions(gem_name, raw_versions)
    ensure
      pool.checkin(client) if client
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
      @pool_mutex.synchronize do
        @rate_limit_mutexes[remote_host] ||= Mutex.new
        @gem_source_client_pools[remote_host] ||= Pool.new(MAX_CONNECTIONS_PER_HOST) do
          if (uri = source_uris[remote_host])
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
      @rate_limit_mutexes[remote_host].synchronize do
        elapsed = Time.now - @last_request_time[remote_host]
        sleep(RATE_LIMIT_INTERVAL - elapsed) if elapsed < RATE_LIMIT_INTERVAL
        @last_request_time[remote_host] = Time.now
      end
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
          return @connections.pop unless @connections.empty?

          if @created_count < @max_connections
            @created_count += 1
            return @create_connection_proc.call
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

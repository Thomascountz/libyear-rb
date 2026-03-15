# frozen_string_literal: true

require "json"
require "pathname"

module LibyearRb
  module GemInfoCacher
    CACHE_EXPIRATION = 86_400 # 24 hours in seconds

    def with_cache(remote_host, gem_name, &block)
      if ENV["SKIP_CACHE"] == "1"
        return block.call
      end

      cache_file_path = cache_file_path(remote_host, gem_name)
      if cache_valid?(cache_file_path)
        JSON.parse(cache_file_path.read)
      else
        block.call.tap do |data|
          return [] unless data

          cache_file_path.dirname.mkpath
          cache_file_path.write(JSON.dump(data))
          cache_file_path.utime(Time.now, Time.now)
        end
      end
    end

    private

    def cache_valid?(cache_file_path)
      return false unless cache_file_path.exist?

      cache_age = Time.now - cache_file_path.mtime
      cache_age < CACHE_EXPIRATION
    end

    def cache_dir
      ENV["XDG_CACHE_HOME"] || Pathname.new(Dir.home).join(".cache")
    end

    def cache_file_path(remote_host, gem_name)
      host_key = remote_host.gsub(/\W/, "_")
      cache_dir.join("libyear-rb", host_key, "#{gem_name}.json")
    end
  end
end

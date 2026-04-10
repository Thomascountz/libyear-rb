# frozen_string_literal: true

require "json"
require "pathname"

module LibyearRb
  class FileCache
    CACHE_EXPIRATION = 86_400 # 24 hours in seconds

    attr_reader :cache_dir

    def initialize(cache_dir: ENV["XDG_CACHE_HOME"] || File.join(Dir.home, ".cache"), skip_cache: ENV["SKIP_CACHE"] == "1")
      @cache_dir = Pathname.new(cache_dir)
      @skip_cache = skip_cache
    end

    def fetch(remote_host, gem_name)
      return yield if @skip_cache

      path = cache_file_path(remote_host, gem_name)
      if cache_valid?(path)
        JSON.parse(path.read)
      else
        yield.tap do |data|
          return [] unless data

          path.dirname.mkpath
          path.write(JSON.dump(data))
          path.utime(Time.now, Time.now)
        end
      end
    end

    private

    def cache_valid?(path)
      return false unless path.exist?

      cache_age = Time.now - path.mtime
      cache_age < CACHE_EXPIRATION
    end

    def cache_file_path(remote_host, gem_name)
      host_key = remote_host.gsub(/\W/, "_")
      cache_dir.join("libyear-rb", host_key, "#{gem_name}.json")
    end
  end
end

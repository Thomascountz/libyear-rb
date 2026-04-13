# frozen_string_literal: true

require "json"
require "pathname"

module LibyearRb
  class FileCache
    CACHE_EXPIRATION = 86_400 # 24 hours in seconds
    CACHE_DIR_ROOT = ENV.fetch("XDG_CACHE_HOME", File.join(Dir.home, ".cache"))
    CACHE_DIR_DEFAULT = File.join(CACHE_DIR_ROOT, "libyear-rb")
    SKIP_CACHE = ENV.fetch("SKIP_CACHE", "0") == "1"

    attr_reader :cache_dir

    def initialize(cache_dir: CACHE_DIR_DEFAULT, skip_cache: SKIP_CACHE)
      @cache_dir = Pathname.new(cache_dir)
      @skip_cache = skip_cache
    end

    def fetch(remote_host, gem_name)
      return yield if @skip_cache

      path = cache_file_path(remote_host, gem_name)
      if cache_valid?(path)
        JSON.parse(path.read)
      else
        data = yield
        return data if data.empty?

        path.dirname.mkpath
        path.write(JSON.dump(data))
        path.utime(Time.now, Time.now)
        data
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
      cache_dir.join(host_key, "#{gem_name}.json")
    end
  end
end

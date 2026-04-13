# frozen_string_literal: true

require_relative "test_helper"
require "tmpdir"

class TestFileCache < Minitest::Test
  def test_cache_dir_defaults_to_xdg_cache_home_libyear_rb
    cache = LibyearRb::FileCache.new

    expected_dir = File.join(ENV.fetch("XDG_CACHE_HOME", File.join(Dir.home, ".cache")), "libyear-rb")

    assert_equal expected_dir, cache.cache_dir.to_s
  end

  def test_cache_path_is_lazily_created_using_remote_host_and_gem_name
    cache = LibyearRb::FileCache.new(cache_dir: Dir.mktmpdir)

    expected_path = File.join(cache.cache_dir, "rubygems_org", "rails.json")

    refute_path_exists(expected_path, "Cache file should not exist before fetch")

    cache.fetch("rubygems.org", "rails") { [:cached_data] }

    assert_path_exists(expected_path)
  end

  def test_fetch_yields_when_no_cached_file_exists
    cache = LibyearRb::FileCache.new(cache_dir: Dir.mktmpdir)

    yielded = false
    result = cache.fetch("rubygems.org", "rails") {
      yielded = true
      [:yielded_data]
    }

    assert(yielded, "Block should be yielded when no cached file exists")
    assert_equal [:yielded_data], result
  end

  def test_fetch_returns_cached_data_without_yielding
    cache_dir = Dir.mktmpdir
    cache = LibyearRb::FileCache.new(cache_dir: cache_dir)
    cache.fetch("rubygems.org", "rails") { [:cached_data] }

    yielded = false
    result = cache.fetch("rubygems.org", "rails") {
      yielded = true
      [:yielded_data]
    }

    refute(yielded, "Block should not be yielded when cache is valid")
    assert_equal ["cached_data"], result
  end

  def test_fetch_yields_when_cache_file_is_expired
    cache_dir = Dir.mktmpdir
    cache = LibyearRb::FileCache.new(cache_dir: cache_dir)
    cache.fetch("rubygems.org", "rails") { [:expired_cached_data] }

    cache_file = Pathname.new(cache_dir).join("rubygems_org", "rails.json")
    expired_time = Time.now - LibyearRb::FileCache::CACHE_EXPIRATION - 1
    cache_file.utime(expired_time, expired_time)

    yielded = false
    result = cache.fetch("rubygems.org", "rails") {
      yielded = true
      [:yielded_data]
    }

    assert(yielded, "Block should be yielded when cache file is expired")
    assert_equal [:yielded_data], result
  end

  def test_fetch_does_not_cache_empty_data
    cache_dir = Dir.mktmpdir
    cache = LibyearRb::FileCache.new(cache_dir: cache_dir)
    cache.fetch("rubygems.org", "rails") { [] }

    yielded = false
    result = cache.fetch("rubygems.org", "rails") {
      yielded = true
      [:yielded_data]
    }

    assert(yielded, "Block should be yielded when empty data was not cached")
    assert_equal [:yielded_data], result
  end

  def test_skip_cache_always_yields
    cache_dir = Dir.mktmpdir
    skip_cache = LibyearRb::FileCache.new(cache_dir: cache_dir, skip_cache: true)
    skip_cache.fetch("rubygems.org", "rails") { [:non_cached_data] }

    yielded = false
    result = skip_cache.fetch("rubygems.org", "rails") {
      yielded = true
      [:yielded_data]
    }

    assert(yielded, "Block should be yielded when skip_cache is true")
    assert_equal [:yielded_data], result
  end
end

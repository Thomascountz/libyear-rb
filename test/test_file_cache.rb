# frozen_string_literal: true

require_relative "test_helper"

class TestFileCache < Minitest::Test
  def test_cache_dir_returns_pathname_when_xdg_cache_home_is_set
    old_value = ENV["XDG_CACHE_HOME"]
    ENV["XDG_CACHE_HOME"] = "/tmp/custom_cache"
    cache = LibyearRb::FileCache.new

    result = cache.cache_dir

    assert_kind_of Pathname, result
    assert_equal "/tmp/custom_cache", result.to_s
  ensure
    ENV["XDG_CACHE_HOME"] = old_value
  end

  def test_cache_dir_returns_pathname_when_xdg_cache_home_is_not_set
    old_value = ENV.delete("XDG_CACHE_HOME")
    cache = LibyearRb::FileCache.new

    result = cache.cache_dir

    assert_kind_of Pathname, result
    assert_equal File.join(Dir.home, ".cache"), result.to_s
  ensure
    ENV["XDG_CACHE_HOME"] = old_value
  end

  def test_cache_dir_uses_explicit_value_over_env
    cache = LibyearRb::FileCache.new(cache_dir: "/tmp/explicit")

    assert_equal "/tmp/explicit", cache.cache_dir.to_s
  end
end

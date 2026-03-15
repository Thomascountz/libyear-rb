# frozen_string_literal: true

require_relative "test_helper"

class TestGemInfoCacher < Minitest::Test
  class CacherHost
    include LibyearRb::GemInfoCacher

    public :cache_dir
  end

  def test_cache_dir_returns_pathname_when_xdg_cache_home_is_set
    old_value = ENV["XDG_CACHE_HOME"]
    ENV["XDG_CACHE_HOME"] = "/tmp/custom_cache"
    cacher = CacherHost.new

    result = cacher.cache_dir

    assert_kind_of Pathname, result
    assert_equal "/tmp/custom_cache", result.to_s
  ensure
    ENV["XDG_CACHE_HOME"] = old_value
  end

  def test_cache_dir_returns_pathname_when_xdg_cache_home_is_not_set
    old_value = ENV.delete("XDG_CACHE_HOME")
    cacher = CacherHost.new

    result = cacher.cache_dir

    assert_kind_of Pathname, result
    assert_equal File.join(Dir.home, ".cache"), result.to_s
  ensure
    ENV["XDG_CACHE_HOME"] = old_value
  end
end

# frozen_string_literal: true

require_relative "test_helper"

class TestFileCache < Minitest::Test
  def test_cache_dir_returns_pathname
    cache = LibyearRb::FileCache.new(cache_dir: "/tmp/test_cache")

    assert_kind_of Pathname, cache.cache_dir
    assert_equal "/tmp/test_cache", cache.cache_dir.to_s
  end
end

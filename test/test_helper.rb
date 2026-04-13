# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "libyear_rb"

require "minitest/autorun"

class Minitest::Test
  def teardown
    LibyearRb.logger = Logger.new(File::NULL)
    LibyearRb.cache = LibyearRb::FileCache.new(skip_cache: true)
    super
  end
end

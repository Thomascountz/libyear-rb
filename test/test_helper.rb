# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "libyear_rb"

require "minitest/autorun"
require "minitest/rg"

class Minitest::Test
  def teardown
    LibyearRb.logger = nil
    LibyearRb.cache = nil
    super
  end
end

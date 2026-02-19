# frozen_string_literal: true

require_relative "test_helper"

class TestConfig < Minitest::Test
  def test_default_logger_is_null_logger
    config = LibyearRb::Config.new

    assert_instance_of Logger, config.logger
  end

  def test_default_as_of_is_today
    config = LibyearRb::Config.new

    assert_equal Date.today, config.as_of
  end

  def test_default_use_cache_is_true
    config = LibyearRb::Config.new

    assert config.use_cache
    assert_predicate config, :use_cache?
  end

  def test_accepts_custom_logger
    logger = Logger.new($stdout)
    config = LibyearRb::Config.new(logger: logger)

    assert_same logger, config.logger
  end

  def test_accepts_custom_as_of_date
    date = Date.new(2024, 6, 15)
    config = LibyearRb::Config.new(as_of: date)

    assert_equal date, config.as_of
  end

  def test_accepts_use_cache_false
    config = LibyearRb::Config.new(use_cache: false)

    refute config.use_cache
    refute_predicate config, :use_cache?
  end

  def test_is_frozen
    config = LibyearRb::Config.new

    assert_predicate config, :frozen?
  end
end

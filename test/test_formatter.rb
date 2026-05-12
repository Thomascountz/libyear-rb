# frozen_string_literal: true

require_relative "test_helper"
require "libyear_rb/formatters/formatter"

class TestFormatter < Minitest::Test
  def test_returns_plaintext_formatter
    assert_equal LibyearRb::PlaintextFormatter, LibyearRb::Formatter["plaintext"]
  end

  def test_returns_curses_formatter
    assert_equal "LibyearRb::CursesFormatter", LibyearRb::Formatter["curses"].name
  end

  def test_lookup_is_case_insensitive
    assert_equal LibyearRb::PlaintextFormatter, LibyearRb::Formatter["Plaintext"]
    assert_equal LibyearRb::PlaintextFormatter, LibyearRb::Formatter["PLAINTEXT"]
  end

  def test_raises_for_unknown_formatter
    error = assert_raises(ArgumentError) { LibyearRb::Formatter["nonexistent"] }

    assert_includes error.message, "Unknown formatter"
    assert_includes error.message, "nonexistent"
    assert_includes error.message, "plaintext"
    assert_includes error.message, "curses"
  end
end

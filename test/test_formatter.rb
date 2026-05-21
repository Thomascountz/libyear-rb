# frozen_string_literal: true

require_relative "test_helper"
require "libyear_rb/formatters/formatter"

class TestFormatter < Minitest::Test
  def test_returns_plaintext_formatter
    assert_equal LibyearRb::PlaintextFormatter, LibyearRb::Formatter.for("plaintext")
  end

  def test_raises_for_unknown_formatter
    error = assert_raises(ArgumentError) { LibyearRb::Formatter.for("nonexistent") }

    assert_includes error.message, "Unknown formatter"
    assert_includes error.message, "nonexistent"
    assert_includes error.message, "plaintext"
  end
end

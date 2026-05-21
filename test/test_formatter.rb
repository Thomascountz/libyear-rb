# frozen_string_literal: true

require_relative "test_helper"
require "libyear_rb/formatters/formatter"

class TestFormatter < Minitest::Test
  def test_returns_plaintext_formatter
    assert_equal LibyearRb::PlaintextFormatter, LibyearRb::Formatter.for("plaintext")
  end

  def test_returns_json_formatter
    assert_equal LibyearRb::JsonFormatter, LibyearRb::Formatter.for("json")
  end

  def test_raises_for_unknown_formatter
    error = assert_raises(ArgumentError) { LibyearRb::Formatter.for("nonexistent") }

    assert_equal \
      %(Unknown formatter: "nonexistent". Available formatters: plaintext, json.),
      error.message
  end
end

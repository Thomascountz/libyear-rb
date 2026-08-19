# frozen_string_literal: true

require_relative "test_helper"
require "libyear_rb/cli"
require "libyear_rb/formatters/plaintext_formatter"
require "libyear_rb/formatters/json_formatter"

class TestCLI < Minitest::Test
  def test_default_options
    parsed_options = parse_options([])

    assert_equal LibyearRb::PlaintextFormatter, parsed_options[:formatter]
    assert parsed_options[:indirect]
    assert_equal LibyearRb::Sorter.parse(LibyearRb::Sorter::DEFAULT_SPEC), parsed_options[:sorters]
  end

  def test_no_indirect_flag
    parsed_options = parse_options(["--no-indirect"])

    refute parsed_options[:indirect]
  end

  def test_indirect_flag
    parsed_options = parse_options(["--indirect"])

    assert parsed_options[:indirect]
  end

  def test_sort_option
    parsed_options = parse_options(["--sort", "versions,name"])

    assert_equal(
      [LibyearRb::Sorter::COLUMNS.fetch("versions"), LibyearRb::Sorter::COLUMNS.fetch("name")],
      parsed_options[:sorters]
    )
  end

  def test_sort_invalid_column
    capture_io do
      error = assert_raises(SystemExit) { parse_options(["--sort", "bogus"]) }
      assert_equal 1, error.status
    end
  end

  def test_verbose_flag
    parsed_options = parse_options(["--verbose"])

    assert parsed_options[:verbose]
  end

  def test_format_option
    parsed_options = parse_options(["--format", "json"])

    assert_equal LibyearRb::JsonFormatter, parsed_options[:formatter]
  end

  def test_format_short_flag
    parsed_options = parse_options(["-f", "json"])

    assert_equal LibyearRb::JsonFormatter, parsed_options[:formatter]
  end

  def test_format_unknown_value
    capture_io do
      error = assert_raises(SystemExit) { parse_options(["--format", "bogus"]) }
      assert_equal 1, error.status
    end
  end

  def test_as_of_option
    parsed_options = parse_options(["--as-of", "2024-06-15"])

    assert_equal Date.new(2024, 6, 15), parsed_options[:as_of]
  end

  def test_as_of_invalid_date
    capture_io do
      error = assert_raises(SystemExit) { parse_options(["--as-of", "not-a-date"]) }
      assert_equal 1, error.status
    end
  end

  def test_help_flag
    out, = capture_io do
      error = assert_raises(SystemExit) { parse_options(["--help"]) }
      assert_equal 0, error.status
    end

    assert_includes out, "Usage: libyear-rb"
  end

  def test_version_flag
    out, = capture_io do
      error = assert_raises(SystemExit) { parse_options(["--version"]) }
      assert_equal 0, error.status
    end

    assert_includes out, "libyear-rb #{LibyearRb::VERSION}"
  end

  def test_positional_argument_is_preserved
    cli = LibyearRb::CLI.new(["path/to/Gemfile.lock"])
    argv = cli.instance_variable_get(:@argv)

    assert_equal ["path/to/Gemfile.lock"], argv
  end

  def test_positional_argument_with_options
    cli = LibyearRb::CLI.new(["path/to/Gemfile.lock", "--verbose", "-f", "json"])
    argv = cli.instance_variable_get(:@argv)
    parsed_options = cli.instance_variable_get(:@options)

    assert parsed_options[:verbose]
    assert_equal ["path/to/Gemfile.lock"], argv
    assert_equal LibyearRb::JsonFormatter, parsed_options[:formatter]
  end

  private

  def parse_options(args)
    cli = LibyearRb::CLI.new(args)
    cli.instance_variable_get(:@options)
  end
end

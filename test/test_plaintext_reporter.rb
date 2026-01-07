# frozen_string_literal: true

require_relative "test_helper"
require "stringio"

class TestPlaintextReporter < Minitest::Test
  def test_formats_single_outdated_gem
    output = StringIO.new
    reporter = LibyearRb::PlaintextReporter.new(io: output)
    results = [
      LibyearRb::Result.new(
        name: "rails",
        current_version: "6.0.0",
        current_version_release_date: Date.new(2019, 8, 16),
        latest_version: "7.1.0",
        latest_version_release_date: Date.new(2023, 10, 5),
        version_distance: 12,
        libyear_in_days: 1511,
        is_direct: true
      )
    ]

    reporter.generate(results)

    expected = <<~OUTPUT
           Gem    Current    Current Date    Latest    Latest Date    Versions    Days    Years
      ........ .......... ............... ......... .............. ........... ....... ........
         rails      6.0.0      2019-08-16     7.1.0     2023-10-05          12    1511     4.14
      System is 4.14 libyears behind
      Total releases behind: 12
    OUTPUT
    assert_equal expected, output.string
  end

  def test_formats_multiple_outdated_gems_sorted_by_name
    output = StringIO.new
    reporter = LibyearRb::PlaintextReporter.new(io: output)
    results = [
      LibyearRb::Result.new(
        name: "zeitwerk",
        current_version: "2.5.0",
        current_version_release_date: Date.new(2020, 1, 1),
        latest_version: "2.6.0",
        latest_version_release_date: Date.new(2021, 1, 1),
        version_distance: 3,
        libyear_in_days: 180,
        is_direct: true
      ),
      LibyearRb::Result.new(
        name: "activerecord",
        current_version: "6.0.0",
        current_version_release_date: Date.new(2020, 1, 1),
        latest_version: "7.0.0",
        latest_version_release_date: Date.new(2021, 1, 1),
        version_distance: 8,
        libyear_in_days: 730,
        is_direct: true
      )
    ]

    reporter.generate(results)

    expected = <<~OUTPUT
                  Gem    Current    Current Date    Latest    Latest Date    Versions    Days    Years
      ............... .......... ............... ......... .............. ........... ....... ........
         activerecord      6.0.0      2020-01-01     7.0.0     2021-01-01           8     730     2.00
             zeitwerk      2.5.0      2020-01-01     2.6.0     2021-01-01           3     180     0.49
      System is 2.49 libyears behind
      Total releases behind: 11
    OUTPUT
    assert_equal expected, output.string
  end

  def test_excludes_up_to_date_gems
    output = StringIO.new
    reporter = LibyearRb::PlaintextReporter.new(io: output)
    results = [
      LibyearRb::Result.new(
        name: "outdated",
        current_version: "1.0.0",
        current_version_release_date: Date.new(2020, 1, 1),
        latest_version: "2.0.0",
        latest_version_release_date: Date.new(2021, 1, 1),
        version_distance: 5,
        libyear_in_days: 365,
        is_direct: true
      ),
      LibyearRb::Result.new(
        name: "current",
        current_version: "1.0.0",
        current_version_release_date: Date.new(2020, 1, 1),
        latest_version: "1.0.0",
        latest_version_release_date: Date.new(2020, 1, 1),
        version_distance: 0,
        libyear_in_days: 0,
        is_direct: true
      )
    ]

    reporter.generate(results)

    assert_includes output.string, "outdated"
    refute_includes output.string, "current"
  end

  def test_outputs_nothing_when_empty
    output = StringIO.new
    reporter = LibyearRb::PlaintextReporter.new(io: output)

    reporter.generate([])

    assert_equal "", output.string
  end

  def test_displays_unknown_for_nil_values
    output = StringIO.new
    reporter = LibyearRb::PlaintextReporter.new(io: output)
    results = [
      LibyearRb::Result.new(
        name: "mystery-gem",
        current_version: "1.0.0",
        current_version_release_date: Date.new(2020, 1, 1),
        latest_version: nil,
        latest_version_release_date: nil,
        version_distance: 5,
        libyear_in_days: nil,
        is_direct: true
      )
    ]

    reporter.generate(results)

    expected = <<~OUTPUT
                 Gem    Current    Current Date     Latest    Latest Date    Versions       Days      Years
      .............. .......... ............... .......... .............. ........... .......... ..........
         mystery-gem      1.0.0      2020-01-01    Unknown        Unknown           5    Unknown    Unknown
      System is 0.00 libyears behind
      Total releases behind: 5
    OUTPUT
    assert_equal expected, output.string
  end
end

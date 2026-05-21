# frozen_string_literal: true

require_relative "test_helper"
require "libyear_rb/formatters/json_formatter"
require "json"
require "stringio"

class TestJsonFormatter < Minitest::Test
  def test_formats_outdated_and_current_gems_sorted_by_name
    output = StringIO.new
    formatter = LibyearRb::JsonFormatter.new(io: output)
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
        is_direct: false
      )
    ]

    formatter.generate(results)

    expected = <<~JSON
      {
        "gems": [
          {
            "name": "activerecord",
            "current_version": "6.0.0",
            "current_version_release_date": "2020-01-01",
            "latest_version": "7.0.0",
            "latest_version_release_date": "2021-01-01",
            "version_distance": 8,
            "libyear_in_days": 730,
            "direct": false
          },
          {
            "name": "zeitwerk",
            "current_version": "2.5.0",
            "current_version_release_date": "2020-01-01",
            "latest_version": "2.6.0",
            "latest_version_release_date": "2021-01-01",
            "version_distance": 3,
            "libyear_in_days": 180,
            "direct": true
          }
        ],
        "summary": {
          "libyears_behind": 2.49,
          "total_releases_behind": 11
        }
      }
    JSON
    assert_equal expected, output.string
  end

  def test_includes_up_to_date_gems
    output = StringIO.new
    formatter = LibyearRb::JsonFormatter.new(io: output)
    results = [
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

    formatter.generate(results)
    parsed = JSON.parse(output.string)

    assert_equal ["current"], parsed["gems"].map { |g| g["name"] }
    assert_equal 0, parsed["summary"]["total_releases_behind"]
    assert_in_delta 0.0, parsed["summary"]["libyears_behind"], 0.001
  end

  def test_outputs_empty_collection_when_no_results
    output = StringIO.new
    formatter = LibyearRb::JsonFormatter.new(io: output)

    formatter.generate([])
    parsed = JSON.parse(output.string)

    assert_equal [], parsed["gems"]
    assert_equal 0, parsed["summary"]["total_releases_behind"]
    assert_in_delta 0.0, parsed["summary"]["libyears_behind"], 0.001
  end

  def test_emits_null_for_unknown_values
    output = StringIO.new
    formatter = LibyearRb::JsonFormatter.new(io: output)
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

    formatter.generate(results)
    parsed = JSON.parse(output.string)

    gem = parsed["gems"].first

    assert_nil gem["latest_version"]
    assert_nil gem["latest_version_release_date"]
    assert_nil gem["libyear_in_days"]
    assert_equal 5, gem["version_distance"]
  end
end

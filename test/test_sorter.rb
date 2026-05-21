# frozen_string_literal: true

require_relative "test_helper"
require "libyear_rb/sorter"

class TestSorter < Minitest::Test
  def test_parse_returns_sorters_in_order
    sorters = LibyearRb::Sorter.parse("libyear,name")

    assert_equal [:libyear_in_days, :name], sorters.map(&:field)
    assert_equal [:desc, :asc], sorters.map(&:direction)
  end

  def test_parse_strips_whitespace
    sorters = LibyearRb::Sorter.parse(" name , versions ")

    assert_equal [:name, :version_distance], sorters.map(&:field)
  end

  def test_parse_raises_for_unknown_column
    error = assert_raises(LibyearRb::Sorter::InvalidSpec) do
      LibyearRb::Sorter.parse("bogus")
    end

    assert_includes error.message, "bogus"
  end

  def test_sort_by_libyear_descending
    sorters = LibyearRb::Sorter.parse("libyear")
    results = [result(name: "a", libyear: 100), result(name: "b", libyear: 500), result(name: "c", libyear: 200)]

    sorted = LibyearRb::Sorter.sort(results, sorters)

    assert_equal ["b", "c", "a"], sorted.map(&:name)
  end

  def test_sort_by_name_ascending
    sorters = LibyearRb::Sorter.parse("name")
    results = [result(name: "c"), result(name: "a"), result(name: "b")]

    sorted = LibyearRb::Sorter.sort(results, sorters)

    assert_equal ["a", "b", "c"], sorted.map(&:name)
  end

  def test_sort_uses_secondary_key_to_break_ties
    sorters = LibyearRb::Sorter.parse("libyear,name")
    results = [result(name: "b", libyear: 100), result(name: "a", libyear: 100), result(name: "c", libyear: 200)]

    sorted = LibyearRb::Sorter.sort(results, sorters)

    assert_equal ["c", "a", "b"], sorted.map(&:name)
  end

  def test_sort_places_nils_last
    sorters = LibyearRb::Sorter.parse("libyear")
    results = [result(name: "a", libyear: nil), result(name: "b", libyear: 500), result(name: "c", libyear: 100)]

    sorted = LibyearRb::Sorter.sort(results, sorters)

    assert_equal ["b", "c", "a"], sorted.map(&:name)
  end

  private

  def result(name:, libyear: 0, version_distance: 0)
    LibyearRb::Result.new(
      name: name,
      current_version: "1.0.0",
      current_version_release_date: Date.new(2020, 1, 1),
      latest_version: "2.0.0",
      latest_version_release_date: Date.new(2021, 1, 1),
      version_distance: version_distance,
      libyear_in_days: libyear,
      is_direct: true
    )
  end
end

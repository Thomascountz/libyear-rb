# frozen_string_literal: true

return unless ENV["SMOKE"] == "1"

require_relative "test_helper"
require "benchmark"

class TestSmoke < Minitest::Test
  def test_small_lockfile
    LibyearRb.cache = LibyearRb::FileCache.new(cache_dir: File::NULL, skip_cache: true)
    lockfile = File.read(File.join(File.expand_path("fixtures", __dir__), "small_Gemfile.lock"))
    as_of = Date.new(2026, 4, 12)

    results = nil
    time = Benchmark.realtime { results = LibyearRb::Runner.new.run(lockfile, as_of: as_of) }
    by_name = results.to_h { |r| [r.name, r] }

    assert_equal 36, results.size
    assert_equal 43, results.sum(&:version_distance)
    assert_in_delta 5.83, results.sum(&:libyear_in_days) / 365.0, 0.01

    rubocop = by_name["rubocop"]

    assert_equal "1.86.1", rubocop.latest_version.to_s
    assert_equal 160, rubocop.libyear_in_days
    assert_equal 9, rubocop.version_distance

    gems = by_name["gems"]

    assert_equal "2.0.0", gems.latest_version.to_s
    assert_equal 508, gems.libyear_in_days
    assert_equal 1, gems.version_distance

    rake = by_name["rake"]

    assert_equal "13.3.1", rake.latest_version.to_s
    assert_equal 0, rake.libyear_in_days
    assert_equal 0, rake.version_distance

    puts "\n  small (#{results.size} gems): #{time.round(2)}s"

    assert_operator time, :<, 5, "small: took #{time.round(2)}s, expected under 5s"
  end

  def test_large_lockfile
    LibyearRb.cache = LibyearRb::FileCache.new(cache_dir: File::NULL, skip_cache: true)
    lockfile = File.read(File.join(File.expand_path("fixtures", __dir__), "large_Gemfile.lock"))
    as_of = Date.new(2026, 4, 12)

    results = nil
    time = Benchmark.realtime { results = LibyearRb::Runner.new.run(lockfile, as_of: as_of) }
    by_name = results.to_h { |r| [r.name, r] }

    assert_equal 308, results.size
    assert_equal 2246, results.sum(&:version_distance)
    assert_in_delta 275.78, results.sum(&:libyear_in_days) / 365.0, 0.01

    rails = by_name["rails"]

    assert_equal "8.1.3", rails.latest_version.to_s
    assert_equal 377, rails.libyear_in_days
    assert_equal 12, rails.version_distance

    nokogiri = by_name["nokogiri"]

    assert_equal "1.19.2", nokogiri.latest_version.to_s
    assert_equal 332, nokogiri.libyear_in_days
    assert_equal 55, nokogiri.version_distance

    ansi = by_name["ansi"]

    assert_equal "1.6.0", ansi.latest_version.to_s
    assert_equal 4091, ansi.libyear_in_days
    assert_equal 1, ansi.version_distance

    active_link_to = by_name["active_link_to"]

    assert_equal "1.0.5", active_link_to.latest_version.to_s
    assert_equal 0, active_link_to.libyear_in_days
    assert_equal 0, active_link_to.version_distance

    puts "\n  large (#{results.size} gems): #{time.round(2)}s"

    assert_operator time, :<, 35, "large: took #{time.round(2)}s, expected under 35s"
  end
end

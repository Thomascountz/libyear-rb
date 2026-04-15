# frozen_string_literal: true

require_relative "test_helper"

class TestDependencyAnalyzer < Minitest::Test
  def test_calculates_version_distance_for_outdated_gem
    spec = LibyearRb::Spec.new(name: "rails", version: "6.0.0", direct: true)
    versions_metadata = [
      LibyearRb::GemVersion.new(name: "rails", number: Gem::Version.new("7.0.0"), created_at: Date.new(2023, 1, 1), prerelease?: false),
      LibyearRb::GemVersion.new(name: "rails", number: Gem::Version.new("6.1.0"), created_at: Date.new(2022, 1, 1), prerelease?: false),
      LibyearRb::GemVersion.new(name: "rails", number: Gem::Version.new("6.0.0"), created_at: Date.new(2021, 1, 1), prerelease?: false)
    ]

    result = LibyearRb::DependencyAnalyzer.freshness(spec, versions_metadata)

    assert_equal 2, result.version_distance
  end

  def test_calculates_libyear_in_days_for_outdated_gem
    spec = LibyearRb::Spec.new(name: "rails", version: "6.0.0", direct: true)
    current_date = Date.new(2021, 1, 1)
    latest_date = Date.new(2023, 1, 1)
    versions_metadata = [
      LibyearRb::GemVersion.new(name: "rails", number: Gem::Version.new("7.0.0"), created_at: latest_date, prerelease?: false),
      LibyearRb::GemVersion.new(name: "rails", number: Gem::Version.new("6.0.0"), created_at: current_date, prerelease?: false)
    ]

    result = LibyearRb::DependencyAnalyzer.freshness(spec, versions_metadata)

    assert_equal 730, result.libyear_in_days
  end

  def test_returns_result_with_zero_distance_when_gem_is_up_to_date
    spec = LibyearRb::Spec.new(name: "rails", version: "7.0.0", direct: true)
    versions_metadata = [
      LibyearRb::GemVersion.new(name: "rails", number: Gem::Version.new("7.0.0"), created_at: Date.new(2023, 1, 1), prerelease?: false)
    ]

    result = LibyearRb::DependencyAnalyzer.freshness(spec, versions_metadata)

    assert_equal 0, result.version_distance
    assert_equal 0, result.libyear_in_days
  end

  def test_returns_nil_when_current_version_not_in_metadata
    spec = LibyearRb::Spec.new(name: "rails", version: "5.0.0", direct: true)
    versions_metadata = [
      LibyearRb::GemVersion.new(name: "rails", number: Gem::Version.new("7.0.0"), created_at: Date.new(2023, 1, 1), prerelease?: false),
      LibyearRb::GemVersion.new(name: "rails", number: Gem::Version.new("6.0.0"), created_at: Date.new(2021, 1, 1), prerelease?: false)
    ]

    result = LibyearRb::DependencyAnalyzer.freshness(spec, versions_metadata)

    assert_nil result
  end

  def test_handles_prerelease_current_version
    spec = LibyearRb::Spec.new(name: "rails", version: "7.0.0.rc1", direct: true)
    versions_metadata = [
      LibyearRb::GemVersion.new(name: "rails", number: Gem::Version.new("7.0.0"), created_at: Date.new(2023, 2, 1), prerelease?: false),
      LibyearRb::GemVersion.new(name: "rails", number: Gem::Version.new("7.0.0.rc1"), created_at: Date.new(2023, 1, 15), prerelease?: true),
      LibyearRb::GemVersion.new(name: "rails", number: Gem::Version.new("6.1.0"), created_at: Date.new(2022, 1, 1), prerelease?: false)
    ]

    result = LibyearRb::DependencyAnalyzer.freshness(spec, versions_metadata)

    refute_nil result
    assert_equal "7.0.0", result.latest_version.to_s
  end

  def test_skips_prerelease_versions_for_stable_current_version
    spec = LibyearRb::Spec.new(name: "rails", version: "6.0.0", direct: true)
    versions_metadata = [
      LibyearRb::GemVersion.new(name: "rails", number: Gem::Version.new("7.0.0.rc1"), created_at: Date.new(2023, 2, 1), prerelease?: true),
      LibyearRb::GemVersion.new(name: "rails", number: Gem::Version.new("6.1.0"), created_at: Date.new(2022, 1, 1), prerelease?: false),
      LibyearRb::GemVersion.new(name: "rails", number: Gem::Version.new("6.0.0"), created_at: Date.new(2021, 1, 1), prerelease?: false)
    ]

    result = LibyearRb::DependencyAnalyzer.freshness(spec, versions_metadata)

    refute_nil result
    assert_equal "6.1.0", result.latest_version.to_s
  end

  def test_ensures_libyear_is_never_negative
    spec = LibyearRb::Spec.new(name: "rails", version: "6.0.0", direct: true)
    # Edge case: latest version has earlier date than current
    versions_metadata = [
      LibyearRb::GemVersion.new(name: "rails", number: Gem::Version.new("6.1.0"), created_at: Date.new(2020, 1, 1), prerelease?: false),
      LibyearRb::GemVersion.new(name: "rails", number: Gem::Version.new("6.0.0"), created_at: Date.new(2021, 1, 1), prerelease?: false)
    ]

    result = LibyearRb::DependencyAnalyzer.freshness(spec, versions_metadata)

    assert_equal 0, result.libyear_in_days
  end

  def test_passes_through_metadata_fields
    spec = LibyearRb::Spec.new(name: "rails", version: "6.0.0", direct: true)
    current_date = Date.new(2021, 1, 1)
    latest_date = Date.new(2023, 1, 1)
    versions_metadata = [
      LibyearRb::GemVersion.new(name: "rails", number: Gem::Version.new("7.0.0"), created_at: latest_date, prerelease?: false),
      LibyearRb::GemVersion.new(name: "rails", number: Gem::Version.new("6.0.0"), created_at: current_date, prerelease?: false)
    ]

    result = LibyearRb::DependencyAnalyzer.freshness(spec, versions_metadata)

    assert_equal "rails", result.name
    assert_equal "6.0.0", result.current_version
    assert_equal current_date, result.current_version_release_date
    assert_equal Gem::Version.new("7.0.0"), result.latest_version
    assert_equal latest_date, result.latest_version_release_date
    assert_equal 1, result.version_distance
    assert_equal 730, result.libyear_in_days
  end

  def test_is_direct_defaults_to_true
    versions_metadata = [
      LibyearRb::GemVersion.new(name: "x", number: Gem::Version.new("2.0"), created_at: Date.today, prerelease?: false),
      LibyearRb::GemVersion.new(name: "x", number: Gem::Version.new("1.0"), created_at: Date.new(2022, 1, 1), prerelease?: false)
    ]

    direct_spec = LibyearRb::Spec.new(name: "x", version: "1.0", direct: true)
    result = LibyearRb::DependencyAnalyzer.freshness(direct_spec, versions_metadata)

    assert result.is_direct

    indirect_spec = LibyearRb::Spec.new(name: "x", version: "1.0")
    result = LibyearRb::DependencyAnalyzer.freshness(indirect_spec, versions_metadata)

    refute result.is_direct
  end
end

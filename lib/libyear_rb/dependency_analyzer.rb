# frozen_string_literal: true

module LibyearRb
  class DependencyAnalyzer
    def self.freshness(spec, versions_metadata)
      current_version_info = versions_metadata.find { |version| version.number == spec.version }

      if current_version_info.nil?
        LibyearRb.logger.warn("Skipping #{spec.name}: installed version #{spec.version} not found in metadata")
        return
      end

      # When the installed version is a prerelease, compare against every
      # release (including prereleases). Otherwise, ignore prereleases so a
      # beta published above the latest stable release does not inflate the
      # version count or freshness gap.
      comparable_versions = if current_version_info.prerelease?
        versions_metadata
      else
        versions_metadata.reject(&:prerelease?)
      end

      latest_version_info = comparable_versions.first

      latest_version = latest_version_info.number
      current_version = current_version_info.number

      latest_release_date = latest_version_info.created_at
      current_release_date = current_version_info.created_at

      version_distance = comparable_versions.index { |version| version.number == current_version }
      libyear_in_days = [(latest_release_date - current_release_date).to_i, 0].max

      Result.new(
        name: spec.name,
        current_version: spec.version,
        current_version_release_date: current_release_date,
        latest_version: latest_version,
        latest_version_release_date: latest_release_date,
        version_distance: version_distance,
        libyear_in_days: libyear_in_days,
        is_direct: spec.direct
      )
    end
  end
end

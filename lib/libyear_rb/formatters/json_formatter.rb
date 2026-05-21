# frozen_string_literal: true

require "json"

module LibyearRb
  class JsonFormatter < Formatter
    def generate(results)
      total_days = results.sum { |r| r.libyear_in_days || 0 }
      total_versions = results.sum { |r| r.version_distance || 0 }

      visible_results = @indirect ? results : results.select(&:is_direct)

      payload = {
        gems: visible_results.sort_by(&:name).map { |result| gem_hash(result) },
        summary: {
          libyears_behind: (total_days / 365.0).round(2),
          total_releases_behind: total_versions
        }
      }

      @io.puts JSON.pretty_generate(payload)
    end

    private

    def gem_hash(result)
      {
        name: result.name.to_s,
        current_version: result.current_version&.to_s,
        current_version_release_date: result.current_version_release_date&.strftime("%Y-%m-%d"),
        latest_version: result.latest_version&.to_s,
        latest_version_release_date: result.latest_version_release_date&.strftime("%Y-%m-%d"),
        version_distance: result.version_distance,
        libyear_in_days: result.libyear_in_days,
        direct: result.is_direct
      }
    end
  end
end

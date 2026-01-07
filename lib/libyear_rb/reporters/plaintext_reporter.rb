# frozen_string_literal: true

module LibyearRb
  class PlaintextReporter < Reporter
    UNKNOWN = "Unknown"
    COLUMN_BUFFER = 3
    HEADERS = ["Gem", "Current", "Current Date", "Latest", "Latest Date", "Versions", "Days", "Years"].freeze

    def generate(results)
      rows = results.sort_by(&:name).filter_map do |result|
        row_for(result) unless result.version_distance.zero?
      end

      return if rows.empty?

      widths = calculate_widths(rows)
      @io.puts format_row(HEADERS, widths)
      @io.puts divider(widths)
      rows.each { |row| @io.puts format_row(row, widths) }

      total_days = results.sum { |r| r.libyear_in_days || 0 }
      total_versions = results.sum { |r| r.version_distance || 0 }
      @io.puts "System is %.2f libyears behind" % (total_days / 365.0)
      @io.puts "Total releases behind: #{total_versions}"
    end

    private

    def row_for(result)
      [
        result.name.to_s,
        result.current_version&.to_s || UNKNOWN,
        result.current_version_release_date&.strftime("%Y-%m-%d") || UNKNOWN,
        result.latest_version&.to_s || UNKNOWN,
        result.latest_version_release_date&.strftime("%Y-%m-%d") || UNKNOWN,
        result.version_distance&.to_s || UNKNOWN,
        result.libyear_in_days&.to_s || UNKNOWN,
        result.libyear_in_days ? "%.2f" % (result.libyear_in_days / 365.0) : UNKNOWN
      ]
    end

    def calculate_widths(rows)
      [HEADERS, *rows].transpose.map { |column| column.map(&:length).max + COLUMN_BUFFER }
    end

    def format_row(values, widths)
      values.zip(widths).map { |value, width| value.rjust(width) }.join(" ")
    end

    def divider(widths)
      widths.map { |w| "." * w }.join(" ")
    end
  end
end

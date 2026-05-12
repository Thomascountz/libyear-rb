# frozen_string_literal: true

module LibyearRb
  class CursesFormatter < Formatter
    HEADERS = [
      "Gem",
      "Current",
      "Current date",
      "Latest",
      "Latest date",
      "Versions",
      "Days",
      "Years"
    ].freeze

    def generate(results)
      rows = results
        .reject { |r| r.version_distance.to_i.zero? }
        .sort_by(&:name)
        .map { |r| Row.from_result(r) }
      return if rows.empty?

      widths = Row.column_widths(HEADERS, rows)
      footer_lines = footer(results)

      Curses.init_screen
      begin
        Curses.cbreak
        Curses.noecho
        Curses.stdscr.keypad(true)
        Curses.curs_set(0)

        Table.new(
          headers: HEADERS,
          rows: rows,
          widths: widths,
          footer_lines: footer_lines
        ).run
      ensure
        Curses.close_screen
      end
    end

    private

    def footer(results)
      dep_count = results.length
      total_days = results.sum { |r| r.libyear_in_days || 0 }
      total_versions = results.sum { |r| r.version_distance || 0 }
      oldness = dep_count.zero? ? 0.0 : (12 * total_days / 365.0 / dep_count)

      [
        "Number of dependencies: #{dep_count}    Oldness: %.2f months/lib" % oldness,
        "System is %.2f libyears and #{total_versions} releases behind" % (total_days / 365.0),
        "Arrow keys to change sort column. s to toggle direction. q to quit."
      ]
    end

    class Row
      UNKNOWN = "Unknown"
      ATTRIBUTES = %i[name current_version current_date latest_version latest_date versions days years].freeze

      attr_reader(*ATTRIBUTES)

      def self.from_result(result)
        days = result.libyear_in_days
        new(
          name: result.name.to_s,
          current_version: version(result.current_version),
          current_date: result.current_version_release_date,
          latest_version: version(result.latest_version),
          latest_date: result.latest_version_release_date,
          versions: result.version_distance,
          days: days,
          years: days ? (days / 365.0).round(2) : nil
        )
      end

      def self.version(value)
        return nil if value.nil?

        Gem::Version.new(value)
      rescue ArgumentError
        value.to_s
      end

      def self.column_widths(headers, rows)
        columns = [headers, *rows.map(&:formatted_cells)].transpose
        columns.zip(headers).map do |column, header|
          [column.map(&:length).max, header.length + 2].max
        end
      end

      def initialize(name:, current_version:, current_date:, latest_version:, latest_date:, versions:, days:, years:)
        @name = name
        @current_version = current_version
        @current_date = current_date
        @latest_version = latest_version
        @latest_date = latest_date
        @versions = versions
        @days = days
        @years = years
      end

      def sort_key(column)
        public_send(ATTRIBUTES[column])
      end

      def formatted_cells
        ATTRIBUTES.map { |attr| format_cell(public_send(attr)) }
      end

      private

      def format_cell(value)
        case value
        when nil then UNKNOWN
        when Date then value.strftime("%Y-%m-%d")
        when Float then "%.2f" % value
        else value.to_s
        end
      end
    end

    class Table
      def initialize(headers:, rows:, widths:, footer_lines:)
        @headers = headers
        @rows = rows
        @widths = widths
        @footer_lines = footer_lines
        @focused_column = 0
        @direction = :asc
        @scroll_top = 0
        reorder!
      end

      def run
        loop do
          render
          case Curses.getch
          when Curses::KEY_LEFT, "h"
            @focused_column = [@focused_column - 1, 0].max
            reorder!
          when Curses::KEY_RIGHT, "l"
            @focused_column = [@focused_column + 1, @headers.length - 1].min
            reorder!
          when Curses::KEY_UP, "k"
            @scroll_top = (@scroll_top - 1).clamp(0, max_scroll_top)
          when Curses::KEY_DOWN, "j"
            @scroll_top = (@scroll_top + 1).clamp(0, max_scroll_top)
          when "s"
            @direction = (@direction == :asc) ? :desc : :asc
            reorder!
          when "q", 3 # Ctrl-C
            break
          end
        end
      end

      private

      def reorder!
        nils, non_nils = @rows.partition { |row| row.sort_key(@focused_column).nil? }
        sorted = non_nils.sort_by { |row| row.sort_key(@focused_column) }
        sorted.reverse! if @direction == :desc
        @rows = sorted + nils
        @scroll_top = 0
      end

      def render
        Curses.clear
        draw_header
        draw_rows
        draw_footer
        Curses.refresh
      end

      def draw_header
        cells = @headers.each_with_index.map do |title, i|
          truncate_or_pad("#{title}#{sort_marker(i)}", @widths[i])
        end

        Curses.setpos(0, 0)
        Curses.attron(Curses::A_REVERSE) { Curses.addstr(cells.join(" ")) }
      end

      def sort_marker(column)
        return "" unless column == @focused_column

        (@direction == :asc) ? " ▼" : " ▲"
      end

      def draw_rows
        height = visible_row_count
        height.times do |i|
          row = @rows[@scroll_top + i]
          break unless row

          line = row.formatted_cells.each_with_index.map { |cell, col|
            truncate_or_pad(cell, @widths[col])
          }.join(" ")

          Curses.setpos(i + 1, 0)
          Curses.addstr(line)
        end
      end

      def draw_footer
        y = Curses.lines - @footer_lines.length
        @footer_lines.each_with_index do |text, i|
          Curses.setpos(y + i, 0)
          Curses.addstr(text)
        end
      end

      def visible_row_count
        [Curses.lines - 1 - @footer_lines.length, @rows.length].min
      end

      def max_scroll_top
        [@rows.length - visible_row_count, 0].max
      end

      def truncate_or_pad(text, width)
        if text.length > width
          text[0, width]
        else
          text.ljust(width)
        end
      end
    end
  end
end

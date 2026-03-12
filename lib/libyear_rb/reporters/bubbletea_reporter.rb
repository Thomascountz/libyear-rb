# frozen_string_literal: true

require "bubbles"
require "bubbletea"

class SortableTable < Bubbles::Table
  attr_writer :footer

  def initialize(...)
    super
    @direction = :asc
    @focused_header = 0
  end

  def update(message)
    super

    # Take care not to overwrite superclass messages.
    # This would lead to two events firing.
    case message
    when Bubbletea::KeyMessage
      case message.to_s
      when "s"
        @direction = (@direction == :asc ? :desc : :asc)
      when "left"
        move_left
      when "right"
        move_right
      when "q"
        return [self, Bubbletea.quit]
      end
    end

    reorder!

    [self, nil]
  end

  def view
    super + "\n\n" + footer
  end

  private

  attr_reader :footer

  def render_header
    cells = []
    @columns.each_with_index do |col, i|
      if i == @focused_header
        direction = @direction == :asc ? "▼" : "▲"
        text = truncate_or_pad("#{col.title} #{direction}", col.width)
        cells << (@focused_header_style ? @focused_header_style.render(text) : "\e[7m#{text}\e[0m")
      else
        text = truncate_or_pad(col.title, col.width)
        cells << "\e[1m#{text}\e[0m"
      end
    end

    cells.join(" ")
  end

  def reorder!
    self.rows = rows.sort_by do |row|
      v = row[@focused_header]
      /\d/.match?(v[0]) ? v.to_f : v.to_s
    end
    self.rows = rows.reverse if @direction == :desc
  end

  def move_left
    @focused_header -= 1 unless @focused_header == 0
  end

  def move_right
    @focused_header += 1 unless @focused_header == @columns.length - 1
  end
end

module LibyearRb
  class BubbleteaReporter < Reporter
    UNKNOWN = "Unknown"

    def generate(results, dep_count)
      Bubbletea.run(
        App.new(results, dep_count),
        alt_screen: true
      )
    end

    private

    class App
      include Bubbletea::Model

      HEADERS = [
        "Gem",
        "Current",
        "Current date",
        "Latest",
        "Latest date",
        "Versions",
        "Days",
        "Years",
      ].freeze

      def initialize(results, dep_count)
        rows = results.sort_by(&:name).filter_map do |result|
          row_for(result) unless result.version_distance.zero?
        end

        columns = [HEADERS, *rows].transpose.map do |column|
          title = column[0]
          title_with_direction_length = column[0].length + 2
          width = column.map(&:length).concat([title_with_direction_length]).max
          { title:, width: }
        end

        @table = SortableTable.new(columns:, rows:)
        @table.footer = footer(results:, dep_count:)
      end

      def init
        [self, nil]
      end

      def update(message)
        if message.is_a?(Bubbletea::WindowSizeMessage)
          # If table (with header and footer) is too high for the window, display
          # fewer rows of the table so there is room for header and footer.
          # If the table is smaller than that, reduce the "table height" so that
          # the footer stays put with only 1 divider row.
          #
          # Header height (1) + header divider (1) + footer height (3) + footer divider (1) = 6
          table.height = [message.height - 6, table.rows.length].min
          nil
        else
          table.update(message)
        end
      end

      def view
        table.view
      end

      private

      attr_reader :table

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

      def footer(results:, dep_count:)
        lines = []
        total_days = results.sum { |r| r.libyear_in_days || 0 }
        total_versions = results.sum { |r| r.version_distance || 0 }
        lines << "Number of dependencies: #{dep_count}                 Oldness: %.2f months/lib" % (12 * total_days / 365.0 / dep_count)
        lines << "System is: %.2f libyears and #{total_versions} releases behind" % (total_days / 365.0)
        lines << "Navigate with arrow keys. s to change sort direction. q to quit."
        lines.join("\n")
      end
    end
  end
end

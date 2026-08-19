# frozen_string_literal: true

module LibyearRb
  SortColumn = Data.define(:field, :direction) do
    def compare(a, b)
      av = a.public_send(field)
      bv = b.public_send(field)
      return 0 if av.nil? && bv.nil?
      return 1 if av.nil?
      return -1 if bv.nil?
      (direction == :desc) ? bv <=> av : av <=> bv
    end
  end

  module Sorter
    DEFAULT_SPEC = "libyear,name"

    COLUMNS = {
      "name" => SortColumn.new(field: :name, direction: :asc),
      "latest-date" => SortColumn.new(field: :latest_version_release_date, direction: :desc),
      "versions" => SortColumn.new(field: :version_distance, direction: :desc),
      "libyear" => SortColumn.new(field: :libyear_in_days, direction: :desc)
    }.freeze

    InvalidSpec = Class.new(ArgumentError)

    class << self
      def parse(spec)
        spec.to_s.split(",").map do |part|
          column = part.strip
          unless COLUMNS.key?(column)
            raise InvalidSpec, "Unknown sort column: #{column.inspect}. Available columns: #{COLUMNS.keys.join(", ")}."
          end
          COLUMNS.fetch(column)
        end
      end

      def sort(results, sorters)
        results.sort do |a, b|
          cmp = 0
          sorters.each do |sorter|
            cmp = sorter.compare(a, b)
            break unless cmp.zero?
          end
          cmp
        end
      end
    end
  end
end

# frozen_string_literal: true

module LibyearRb
  class Formatter
    NAMES = %w[plaintext].freeze

    class << self
      def for(name)
        case name
        when "plaintext"
          require "libyear_rb/formatters/plaintext_formatter"
          PlaintextFormatter
        else
          raise ArgumentError, "Unknown formatter: #{name.inspect}. Available formatters: #{NAMES.join(", ")}."
        end
      end
    end

    def initialize(io: $stdout)
      @io = io
    end

    def generate(results)
      raise NotImplementedError, "Subclasses must implement the generate method"
    end
  end
end

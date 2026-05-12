# frozen_string_literal: true

module LibyearRb
  class Formatter
    NAMES = %w[plaintext curses].freeze

    class << self
      def [](name)
        case name.to_s.downcase
        when "plaintext"
          require "libyear_rb/formatters/plaintext_formatter"
          PlaintextFormatter
        when "curses"
          begin
            require "curses"
          rescue LoadError
            raise ArgumentError, "The curses formatter requires the `curses` gem. " \
              "Install it with `gem install curses` or add `gem \"curses\"` to your Gemfile."
          end
          require "libyear_rb/formatters/curses_formatter"
          CursesFormatter
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

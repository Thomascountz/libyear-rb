# frozen_string_literal: true

module LibyearRb
  class Formatter
    class << self
      def [](name)
        raise ArgumentError, "Formatter name must contain only letters." unless name.match?(/\A[a-zA-Z]+\z/)

        gem_name = "libyear-rb-#{name.downcase}-formatter"
        file_name = "libyear_rb/formatters/#{name.downcase}_formatter"
        class_name = "#{name.capitalize}Formatter"

        begin
          gem gem_name
        rescue Gem::LoadError
          # Gem may be loadable without activation (e.g. already on the load path)
        end

        require file_name
        LibyearRb.const_get(class_name, false)
      rescue LoadError
        raise ArgumentError, "Formatter gem #{gem_name} could not be loaded."
      rescue NameError
        raise ArgumentError, "Formatter gem #{gem_name} does not define LibyearRb::#{class_name}."
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

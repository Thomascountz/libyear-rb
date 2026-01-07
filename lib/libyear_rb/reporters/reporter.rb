# frozen_string_literal: true

module LibyearRb
  class Reporter
    def initialize(io: $stdout)
      @io = io
    end

    def generate(dependency_freshness)
      raise NotImplementedError, "Subclasses must implement the generate method"
    end
  end
end

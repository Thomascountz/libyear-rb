# frozen_string_literal: true

module LibyearRb
  class Reporter
    def generate(dependency_freshness)
      raise NotImplementedError, "Subclasses must implement the generate method"
    end
  end
end

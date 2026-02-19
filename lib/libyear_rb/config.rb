# frozen_string_literal: true

module LibyearRb
  Config = Data.define(:logger, :as_of, :use_cache) do
    def initialize(logger: Logger.new(IO::NULL), as_of: Date.today, use_cache: true)
      super
    end

    def use_cache? = use_cache
  end
end

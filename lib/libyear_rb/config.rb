# frozen_string_literal: true

module LibyearRb
  class Config
    attr_accessor :logger, :as_of, :use_cache

    def initialize(logger: Logger.new(IO::NULL), as_of: Date.today, use_cache: true)
      @logger = logger
      @as_of = as_of
      @use_cache = use_cache
    end

    alias_method(:use_cache?, :use_cache)
  end
end

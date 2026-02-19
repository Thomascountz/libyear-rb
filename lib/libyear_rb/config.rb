# frozen_string_literal: true

module LibyearRb
  class Config
    attr_reader :logger, :as_of, :use_cache

    def initialize(logger: Logger.new(IO::NULL), as_of: Date.today, use_cache: true)
      self.logger = logger
      self.as_of = as_of
      self.use_cache = use_cache
    end

    # Logger instance for diagnostic output.
    # Must respond to standard Logger methods (:info, :warn, :debug, etc.)
    # Defaults to a null logger (Logger.new(IO::NULL)).
    def logger=(value)
      raise ArgumentError, "'logger' must respond to :warn" unless value.respond_to?(:warn)

      @logger = value
    end

    # Date used to filter gem versions for historical analysis.
    # Only versions released on or before this date are considered.
    # Defaults to Date.today.
    def as_of=(value)
      raise ArgumentError, "'as_of' must be a Date" unless value.is_a?(Date)

      @as_of = value
    end

    # Whether to read from and write to the gem metadata cache.
    # Defaults to true.
    def use_cache=(value)
      raise ArgumentError, "'use_cache' must be true or false" unless [true, false].include?(value)

      @use_cache = value
    end

    def use_cache? = @use_cache
  end
end

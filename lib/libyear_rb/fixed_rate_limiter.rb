# frozen_string_literal: true

module LibyearRb
  class FixedRateLimiter
    def initialize(rate:)
      @interval = 1.0 / rate
      @mutex = Mutex.new
      @next_available_at = monotonic_time
    end

    def acquire
      delay = @mutex.synchronize do
        now = monotonic_time
        wait = [@next_available_at - now, 0].max
        @next_available_at = [@next_available_at, now].max + @interval
        wait
      end

      sleep(delay) if delay.positive?
    end

    private

    def monotonic_time
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end

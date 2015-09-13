module SparkleMotion
  # Helper class to hold onto stats about requests made to the bridges.
  #
  # NOTE: Methods ending with `!` are *not* thread-safe, methods without it *are*.
  #
  # TODO: Track things by light index, bridge, etc...
  class Results
    attr_reader :start_time, :end_time, :successes, :failures, :hard_timeouts,
                :soft_timeouts

    def initialize(logger:)
      @logger = logger
      @mutex  = Mutex.new
      clear!
    end

    def clear!
      @successes      = 0
      @failures       = 0
      @hard_timeouts  = 0
      @soft_timeouts  = 0
    end

    def begin!; @start_time ||= Time.now.to_f; end
    def done!; @end_time ||= Time.now.to_f; end

    # TODO: Colorized output for all feedback types, or running counters, or
    # TODO: something...

    def success!(info = nil)
      @logger.error { info } if info
      @successes += 1
    end

    def failure!(info = nil)
      @logger.error { info } if info
      @failures += 1
    end

    def hard_timeout!(info = nil)
      @logger.error { info } if info
      @hard_timeouts += 1
    end

    def soft_timeout!(info = nil)
      @logger.error { info } if info
      @soft_timeouts += 1
    end

    def elapsed; @end_time - @start_time; end
    def requests; @successes + @failures + @hard_timeouts + @soft_timeouts; end
    def all_failures; @failures + @hard_timeouts + @soft_timeouts; end

    def requests_sec; ratio(requests, elapsed); end
    def successes_sec; ratio(successes, elapsed); end
    def failures_sec; ratio(failures, elapsed); end
    def hard_timeouts_sec; ratio(hard_timeouts, elapsed); end
    def soft_timeouts_sec; ratio(soft_timeouts, elapsed); end

    def failure_rate; ratio(all_failures * 100, requests); end

    def add_from(other)
      @mutex.synchronize do
        @successes      += other.successes
        @failures       += other.failures
        @hard_timeouts  += other.hard_timeouts
        @soft_timeouts  += other.soft_timeouts
      end
    end

  protected

    def ratio(num, denom)
      return nil unless num && denom && denom > 0
      num / denom.to_f
    end
  end
end

module SparkleMotion
  # Abstract base class to perform an action at a specified maximum rate.
  class TickTask < ManagedTask
    def initialize(name, duration, logger)
      @duration = duration
      super(name, :late, logger)
    end

    def iterate
      # Try to adhere to a specific tick frequency...
      before_time = Time.now.to_f
      tick(before_time)
      elapsed = Time.now.to_f - before_time
      sleep @duration - elapsed if elapsed < @duration
    end

    def tick(_time); fail "Must be implemented by a sub-class!"; end
  end
end

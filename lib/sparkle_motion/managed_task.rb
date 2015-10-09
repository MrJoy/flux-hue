module SparkleMotion
  # Extend `Task` to loop and terminate gracefully when signalled to do so.
  class ManagedTask < Task
    def initialize(name, when_to_signal, logger)
      @when_to_signal = when_to_signal
      super(name, logger)
    end

    def start
      @end_signal = false
      super
    end

    def stop; @end_signal = true; end

    def iterate; fail "Must be implemented by sub-class!"; end

  protected

    def perform
      loop do
        break if @end_signal && @when_to_signal == :early
        iterate
        break if @end_signal && @when_to_signal == :late
      end
    end
  end
end

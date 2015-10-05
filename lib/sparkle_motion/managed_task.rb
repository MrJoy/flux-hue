module SparkleMotion
  # Extend `UnmanagedTask` to loop and terminate gracefully when signalled to do so.
  class ManagedTask < Task
    def initialize(name, when_to_signal, logger, &callback)
      @when_to_signal = when_to_signal
      super(name, logger) { task_loop(&callback) }
    end

    def start
      @end_signal = false
      super
    end

    def stop
      @end_signal = true
      # TODO: Separate out the join step and make it the caller's responsibility.
      await
    end

  protected

    def task_loop(&callback)
      loop do
        break if @end_signal && @when_to_signal == :early
        callback.call
        break if @end_signal && @when_to_signal == :late
      end
    end
  end
end

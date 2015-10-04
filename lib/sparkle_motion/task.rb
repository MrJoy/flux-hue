module SparkleMotion
  # Wrapper around a frequently-occurring pattern for having a worker thread that's set up early,
  # but not launched until later.
  class Task
    def initialize(&callback)
      @thread = Thread.new do
        Thread.stop
        task_loop(&callback)
      end
    end

    def start
      @end_signal = false
      @thread.run
    end

    def await; @thread.join; end

    def stop
      @end_signal = true
      @thread.join
    end

  protected

    def task_loop(&callback)
      loop do
        callback.call
        break if @end_signal
      end
    end
  end
end

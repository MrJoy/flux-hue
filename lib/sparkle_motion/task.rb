module SparkleMotion
  # Wrapper around a frequently-occurring pattern for having a worker thread that's set up early,
  # but not launched until later.
  class Task
    include FlowControl

    def initialize(name, logger, &callback)
      @name   = name
      @logger = logger
      @thread = Thread.new do
        Thread.stop
        task_loop(&callback)
      end
    end

    def start
      @end_signal = false
      wait_for(@thread, "sleep")
      @thread.run
    end

    def await; @thread.join; end

    def stop
      @logger.info { "Terminating task '#{@name}'..." }
      @end_signal = true
      @thread.join
      @logger.info { "Task '#{@name}' ended." }
    end

  protected

    def task_loop(&callback)
      loop do
        break if @end_signal
        callback.call
      end
    end
  end
end

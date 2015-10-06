module SparkleMotion
  # Abstract base class to wrap up a frequently-occurring pattern for having a worker thread that's
  # set up early, but not launched until later.
  class Task
    attr_accessor :name

    include FlowControl

    def initialize(name, logger, &callback)
      @name   = name
      @logger = logger
      @thread = guarded_thread(name) do
        Thread.stop
        callback.call
      end
    end

    def start
      @logger.info { "#{@name}: Starting task..." }
      wait_for(@thread, "sleep")
      @thread.run
    end

    def await
      @logger.info { "#{@name}: Waiting for task to end..." }
      @thread.join
      @logger.info { "#{@name}: Task has ended!" }
    end

    def stop; fail "Must be implemented by sub-class!"; end

    def status; @thread.status; end
  end
end

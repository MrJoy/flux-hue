module SparkleMotion
  # Abstract base class to wrap up a frequently-occurring pattern for having a worker thread that's
  # set up early, but not launched until later.
  class Task
    attr_accessor :name

    def initialize(name, logger)
      @name   = name
      @logger = logger
      @thread = Thread.new do
        begin
          Thread.stop
          perform
        rescue StandardError => e
          SparkleMotion.logger.error { "#{@name}: Got Exception: #{e.message}" }
          e.backtrace.each do |line|
            SparkleMotion.logger.error { "#{@name}:\t#{line}" }
          end
        end
      end
    end

    def perform; fail "Must be implemented by sub-class!"; end

    def start
      @logger.info { "#{@name}: Starting task..." }
      sleep 0.02 while @thread.status != "sleep"
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

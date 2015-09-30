module SparkleMotion
  # Random helpers related to flow control.
  module FlowControl
    def guard_call(prefix, &block)
      block.call
    rescue StandardError => e
      SparkleMotion.logger.error { "#{prefix}: Got Exception: #{e.message}" }
      e.backtrace.each do |line|
        SparkleMotion.logger.error { "#{prefix}:\t#{line}" }
      end
    end

    def guarded_thread(prefix, &block); Thread.new { guard_call(prefix, &block) }; end

    def any_in_state(threads, state)
      threads = Array(threads)
      threads.find { |th| th.status != state }
    end

    def wait_for(threads, state)
      threads = Array(threads)
      sleep 0.01 while any_in_state(threads, state)
    end
  end
end

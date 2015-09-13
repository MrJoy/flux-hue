module SparkleMotion
  # Random helpers related to flow control.
  module FlowControl
    def guard_call(prefix, &block)
      block.call
    rescue StandardError => e
      SparkleMotion.logger.error { "#{prefix}: Exception for #{prefix}: #{e.message}" }
      SparkleMotion.logger.error { "#{prefix}:\t#{e.backtrace.join("\n#{prefix}:\t")}" }
    end
  end
end

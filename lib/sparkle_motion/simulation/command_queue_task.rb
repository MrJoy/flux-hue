module SparkleMotion
  module Simulation
    # Class that accepts group update commands and runs them in sequence.
    class CommandQueueTask < SparkleMotion::ManagedTask
      def initialize(logger)
        @queue = Queue.new
        @enabled = false
        super("CommandQueueTask", :early, logger) do
          requests = pending_commands
          next if requests.length == 0
          @logger.debug { "Processing #{requests.length} pending commands." }
          # TODO: Gather stats about success/failure...

          # TODO: Only do batches that are spread across bridges?
          Curl::Multi.http(requests, SparkleMotion::Hue::HTTP::MULTI_OPTIONS) do |easy|
            next unless error?(easy)
            rc    = easy.response_code
            body  = easy.body
            @logger.warn { "#{@name}: Request failed: #{easy.url} => #{rc}; #{body}" }
          end
        end
      end

      def <<(val)
        return unless @enabled
        @queue << val
      end

      def enable!; @enabled = true; end
      def disable!; @enabled = false; end

      def clear; @queue.clear; end

    protected

      def error?(easy)
        easy.response_code < 200 || easy.response_code >= 400 || easy.body =~ /error/
      end

      def pending_commands
        sleep 0.1 if @queue.empty?
        requests = []
        requests << @queue.pop until @queue.empty?
        requests
      end
    end
  end
end

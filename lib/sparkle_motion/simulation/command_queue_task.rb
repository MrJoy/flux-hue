module SparkleMotion
  module Simulation
    # Class that accepts group update commands and runs them in sequence.
    class CommandQueueTask < ManagedTask
      def initialize(logger)
        @queue = Queue.new
        super("CommandQueueTask", :early, logger)
      end

      def iterate
        requests = pending_commands
        return unless requests && requests.length > 0
        @logger.debug { "Processing #{requests.length} pending commands." }
        # TODO: Gather stats about success/failure...
        unless USE_LIGHTS
          sleep 0.1
          return
        end

        # TODO: Only do batches that are spread across bridges?
        Curl::Multi.http(requests, SparkleMotion::Hue::HTTP::MULTI_OPTIONS) do |easy|
          next unless error?(easy)
          rc    = easy.response_code
          body  = easy.body
          @logger.warn { "#{@name}: Request failed: #{easy.url} => #{rc}; #{body}" }
        end
      end

      def <<(val); @queue << val; end

      def clear; @queue.clear; end

    protected

      def error?(easy)
        easy.response_code < 200 || easy.response_code >= 400 || easy.body =~ /error/
      end

      def pending_commands
        if @queue.empty?
          sleep 0.1
          return nil
        end
        requests = []
        requests << @queue.pop until @queue.empty?
        requests
      end
    end
  end
end

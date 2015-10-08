module SparkleMotion
  module Simulation
    class CommandQueueTask < SparkleMotion::ManagedTask
      def initialize(logger)
        @queue = Queue.new
        super("CommandQueueTask", :early, logger) do
          requests = pending_commands
          next if requests.length == 0
          LOGGER.debug { "Processing #{requests.length} pending commands." }
          # TODO: Gather stats about success/failure...
          unless USE_LIGHTS
            sleep 0.1
            next
          end
          Curl::Multi.http(requests, SparkleMotion::Hue::HTTP::MULTI_OPTIONS) do |easy|
            next unless error?(easy)
            LOGGER.warn { "#{@name}: Request failed: #{easy.url} => #{rc}; #{body}" }
          end
        end
      end

      def <<(val); @queue << val; end

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

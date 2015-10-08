module SparkleMotion
  module Simulation
    # Task to sweep through various hues on one or more bridges.
    class SweeperTask < SparkleMotion::TickTask
      attr_accessor :command_queue

      include SparkleMotion::Hue::HTTP

      def initialize(targets:, command_queue:, config:, logger:)
        @command_queue  = command_queue
        @hues           = config["values"]
        @transition     = config["transition"]
        @wait           = config["wait"]
        @data           = with_transition_time(@transition, "hue" => 0)
        @targets        = targets
                          .map do |(bridge, group_id)|
                            url = hue_group_endpoint(bridge, group_id)
                            SparkleMotion::Hue::LazyRequestConfig.new(logger, bridge, :put, url) do
                              @data
                            end
                          end

        super("SweeperTask[#{config['name']}]", @wait, logger)

        validate_params!
      end

      def tick(time)
        idx = ((time / @wait) % @hues.length).floor
        # TODO: Recycle hashes?
        return unless USE_SWEEP
        @targets.each do |req|
          @data["hue"] = @hues[idx]
          @command_queue << req
        end
      end

    protected

      def validate_params!
        logger.warn { "#{@name}: Wait should be >= transition!" } if @wait < @transition
        logger.warn { "#{@name}: Wait should be >= 1 second!" } if @wait < 1.0
      end
    end
  end
end

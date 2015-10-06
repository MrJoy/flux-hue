module SparkleMotion
  module Simulation
    # Task to sweep through various hues on one or more bridges.
    class SweeperTask < SparkleMotion::TickTask
      include SparkleMotion::Hue::HTTP

      def initialize(targets:, config:, logger:)
        @targets    = targets
        @hues       = config["values"]
        @transition = config["transition"]
        @wait       = config["wait"]

        super("SweeperTask[#{config['name']}]", @wait, logger)

        validate_params!
      end

      def tick(time)
        idx = ((time / @wait) % @hues.length).floor
        # TODO: Recycle hashes?
        @targets.each do |(bridge, group_id)|
          data = with_transition_time(@transition, "hue" => @hues[idx])
          add_group_command!(bridge, group_id, data)
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

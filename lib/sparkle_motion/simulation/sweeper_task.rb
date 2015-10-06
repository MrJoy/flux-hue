module SparkleMotion
  module Simulation
    # Task to sweep through various hues on one or more bridges.
    class SweeperTask < SparkleMotion::TickTask
      attr_accessor :command_queue

      include SparkleMotion::Hue::HTTP

      def initialize(targets:, command_queue:, config:, logger:)
        @targets        = targets
        @command_queue  = command_queue
        @hues           = config["values"]
        @transition     = config["transition"]
        @wait           = config["wait"]
        @data           = with_transition_time(@transition, "hue" => 0)

        super("SweeperTask[#{config['name']}]", @wait, logger)

        validate_params!
      end

      def tick(time)
        idx = ((time / @wait) % @hues.length).floor
        # TODO: Recycle hashes?
        @targets.each do |(bridge, group_id)|
          @data["hue"] = @hues[idx]
          add_group_command!(bridge, group_id, @data)
        end
      end

    protected

      def add_group_command!(bridge, group_id, data)
        return unless @command_queue
        # TODO: Hoist the hash into something reusable?
        @command_queue << { method:   :put,
                            url:      group_update_url(bridge, group_id),
                            put_data: Oj.dump(data) }.merge(SparkleMotion::Hue::HTTP::EASY_OPTIONS)
      end

      def validate_params!
        logger.warn { "#{@name}: Wait should be >= transition!" } if @wait < @transition
        logger.warn { "#{@name}: Wait should be >= 1 second!" } if @wait < 1.0
      end
    end
  end
end

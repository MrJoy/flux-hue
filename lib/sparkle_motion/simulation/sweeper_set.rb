module SparkleMotion
  module Simulation
    # Manages a set of `SweeperTask`s, and provides a simple DSL for defining them.
    class SweeperSet
      def initialize(bridges, command_queue, logger)
        @bridges       = bridges
        @command_queue = command_queue
        @logger        = logger
        @sweepers      = {}
      end

      def draw(&callback)
        instance_eval(&callback)
      end

      def start
        @sweepers.values.map(&:start)
      end

      def stop
        @sweepers.values.map(&:stop)
      end

      def sweeper(name, targets:, transition:, wait:, hues:)
        targets = targets
                  .map do |(nn, group)|
                    bridge = @bridges[nn]
                    [bridge, bridge["groups"][group]]
                  end
        config  = { hues:       hues,
                    transition: transition,
                    wait:       wait }
        sweeper = SparkleMotion::Simulation::SweeperTask.new(targets:       targets,
                                                             config:        config,
                                                             logger:        @logger,
                                                             command_queue: @command_queue)
        @sweepers[name] = sweeper
      end
    end
  end
end

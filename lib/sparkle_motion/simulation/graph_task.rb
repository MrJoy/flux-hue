module SparkleMotion
  module Simulation
    # Render a graph according to our framerate.
    class GraphTask < TickTask
      def initialize(name, logger)
        super("GraphTask[#{name}]", SparkleMotion::Node::FRAME_PERIOD, logger)
      end

      def tick(time); FINAL_RESULT.update(time); end
    end
  end
end

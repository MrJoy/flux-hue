module SparkleMotion
  module Simulation
    # Render a graph according to our framerate.
    class GraphTask < TickTask
      def initialize(name, logger, graph)
        @graph = graph
        super("GraphTask[#{name}]", SparkleMotion::Node::FRAME_PERIOD, logger)
      end

      def tick(time); @graph.update(time); end
    end
  end
end

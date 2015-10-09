module SparkleMotion
  module Simulation
    # Render a graph according to our framerate.
    class GraphTask < TickTask
      def initialize(name, graph, frame_period, logger)
        @graph = graph
        super("GraphTask[#{name}]", frame_period, logger)
      end

      def tick(time)
        return unless USE_GRAPH
        @graph.update(time)
      end
    end
  end
end

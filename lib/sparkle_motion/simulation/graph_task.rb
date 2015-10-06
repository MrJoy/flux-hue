module SparkleMotion
  module Simulation
    # Render a graph according to our framerate.
    class GraphTask < ManagedTask
      def initialize(name, logger)
        super("GraphTask[#{name}]", :late, logger) do
          t = Time.now.to_f
          FINAL_RESULT.update(t)
          el = Time.now.to_f - t
          # Try to adhere to a specific update frequency...
          sleep SparkleMotion::Node::FRAME_PERIOD - el if el < SparkleMotion::Node::FRAME_PERIOD
        end
      end
    end
  end
end

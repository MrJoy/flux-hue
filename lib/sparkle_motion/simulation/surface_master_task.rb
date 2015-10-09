module SparkleMotion
  module Simulation
    # Task that handles input from a SurfaceMaster device.
    class SurfaceMasterTask < UnmanagedTask
      def initialize(name, controller, logger)
        @controller = controller
        super("SurfaceMasterTask[#{name}]", logger)
      end

      def perform; @controller.start; end
    end
  end
end

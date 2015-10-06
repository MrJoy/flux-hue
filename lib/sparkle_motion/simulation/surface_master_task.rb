module SparkleMotion
  module Simulation
    # Task that handles input from a SurfaceMaster device.
    class SurfaceMasterTask < SparkleMotion::UnmanagedTask
      def initialize(name, controller, logger)
        @controller = controller
        super("InputHandlerTask[#{name}]", logger) { @controller.start }
      end
    end
  end
end

module SparkleMotion
  module Widgets
    # A collection of screens on a device.
    class ScreenSet
      attr_accessor :screens, :state

      def initialize(controllers, graph_set, state, logger)
        @controllers  = controllers
        @graph_set    = graph_set
        @state        = state
        @screens      = {}
        @logger       = logger
      end

      def start
        @screens.values.each do |screen|
          screen.start
          0.01
        end
      end

      def stop
        @screens.values.each do |screen|
          screen.stop
          sleep 0.01
        end
      end

      def draw(&handler)
        instance_eval(&handler)
      end

      def screen(name, controller_name, &handler)
        controller  = @controllers[controller_name]
        @logger.error { "No such controller: '#{controller_name}'!" } unless controller

        @screens[name] = Screen.new(self, @graph_set, controller, state, @logger).draw(&handler)
      end
    end
  end
end

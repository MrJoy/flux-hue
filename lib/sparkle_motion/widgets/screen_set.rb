module SparkleMotion
  module Widgets
    # A collection of screens on a device.
    class ScreenSet
      attr_accessor :screens, :state

      def initialize(controllers, state, logger)
        @controllers  = controllers
        @state        = state
        @screens      = {}
        @default      = nil
        @logger       = logger
      end

      def start; @screens.values.each(&:start); end
      def stop; @screens.values.each(&:stop); end

      def draw(&handler)
        instance_eval(&handler)
        @screens[@default].start if @default
      end

      def screen(name, controller_name, default: false, &handler)
        @default    = name if default
        controller  = @controllers[controller_name]
        @logger.error { "No such controller: '#{controller_name}'!" } unless controller

        @screens[name] = Screen.new(self, controller, state, @logger).draw(&handler)
      end
    end
  end
end

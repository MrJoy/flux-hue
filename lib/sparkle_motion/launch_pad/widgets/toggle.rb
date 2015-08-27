module SparkleMotion
  module LaunchPad
    module Widgets
      # Class to represent a single toggle button.
      class Toggle < Widget
        attr_accessor :on_press

        def initialize(launchpad:, position: nil, x: nil, y: nil, on:, off:, down:, on_press: nil, value: 0)
          super(launchpad: launchpad, position: position, x: x, y: y, width: 1, height: 1, on: on, off: off, down: down, value: value)
          @on_press = on_press
        end

        def render
          val = (value != 0) ? on : off
          if @x
            change_grid(x: 0, y: 0, color: val)
          else
            change_command(position: @position, color: val)
          end
          super
        end

        def update(new_val)
          @value = new_val ? 1 : 0
          render
        end

      protected

        def on_down(x: nil, y: :nil, position: nil)
          @value = (@value == 0) ? 1 : 0
          super(x: x, y: y, position: position)
          on_press.call(value) if on_press
        end
      end
    end
  end
end

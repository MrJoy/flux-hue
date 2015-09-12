module SparkleMotion
  module LaunchPad
    module Widgets
      # Class to represent a slider-style control on a Novation Launchpad.
      class VerticalSlider < Widget
        attr_accessor :on_change

        def initialize(launchpad:, x:, y:, size:, on:, off:, down:, on_change: nil, value: 0)
          super(launchpad:  launchpad,
                x:          x,
                y:          y,
                width:      1,
                height:     size,
                on:         on,
                off:        off,
                down:       down,
                value:      value)
          @on_change = on_change
        end

        def render
          (0..max_v).each do |yy|
            change_grid(x: 0, y: yy, color: (value && value >= yy) ? on : off)
          end
          super
        end

        def update(*args)
          super(*args)
          on_change.call(value) if on_change
        end

      protected

        def on_down(x:, y:)
          @value = y
          super(x: x, y: y)
          on_change.call(value) if on_change
        end
      end
    end
  end
end

module SparkleMotion
  module LaunchPad
    module Widgets
      # Class to represent a slider-style control on a Novation Launchpad.
      class VerticalSlider < Widget
        attr_accessor :on_change, :orbit

        def initialize(launchpad:, position: nil, size:, colors:, on_change: nil, value: 0)
          super(launchpad: launchpad,
                position:  position || position_lp,
                size:      Vector2.new(1, size),
                colors:    colors,
                value:     value)
          @on_change    = on_change
        end

        def render
          (0..max_v).each do |yy|
            change_grid(x: 0, y: yy, color: (value && value >= yy) ? colors.on : colors.off)
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

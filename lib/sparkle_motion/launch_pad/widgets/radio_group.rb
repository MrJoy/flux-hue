module SparkleMotion
  module LaunchPad
    module Widgets
      # Class to represent a radio-button group control on a Novation Launchpad.
      class RadioGroup < Widget
        attr_accessor :on_select, :on_deselect

        def initialize(launchpad:, position:, size:, colors:, on_select: nil, on_deselect: nil,
                       value: nil)
          super(launchpad: launchpad,
                position:  position,
                size:      size,
                colors:    colors,
                value:     value)
          @on_select    = on_select
          @on_deselect  = on_deselect
        end

        def render
          (0..max_x).each do |xx|
            (0..max_y).each do |yy|
              col = (value == index_for(x: xx, y: yy)) ? colors.on : colors.off

              change_grid(x: xx, y: yy, color: col)
            end
          end
        end

        def update(*args)
          super(*args)
          on_select.call(value) if on_select && value
          on_deselect.call(value) if on_deselect && !value
        end

      protected

        def on_down(x:, y:)
          vv = index_for(x: x, y: y)
          vv = nil if value == vv
          @value = vv
          super(x: x, y: y)

          handler = value ? on_select : on_deselect
          handler.call(value) if handler
        end
      end
    end
  end
end

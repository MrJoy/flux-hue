module SparkleMotion
  module LaunchPad
    module Widgets
      # Class to represent a slider-style control on a Novation Launchpad.
      class VerticalSlider < Widget
        attr_accessor :on_change, :orbit

        def initialize(launchpad:, position: nil, size:, colors:, on_change: nil, value: 0,
                       orbit: nil, position_lp: nil, position_no: nil)
          super(launchpad: launchpad,
                position:  position || position_lp,
                size:      Vector2.new(1, size),
                colors:    colors,
                value:     value)
          @orbit        = orbit
          @on_change    = on_change

          attach_orbit_handler!(position_no)
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

        def attach_orbit_handler!(pos_no)
          return unless orbit
          xx = (pos_no.x..(pos_no.x + size.x - 1))
          yy = (pos_no.y..(pos_no.y + size.y - 1))
          orbit.response_to(:grid, :down, x: xx, y: yy) do |_inter, action|
            local_x = action[:control][:x] - pos_no.x
            local_y = (action[:control][:y] - pos_no.y)
            pressed!(x: local_x, y: local_y)
            on_down(x: local_x, y: local_y)
          end
          orbit.response_to(:grid, :up, x: xx, y: yy) do |_inter, action|
            local_x = action[:control][:x] - pos_no.x
            local_y = (action[:control][:y] - pos_no.y)
            released!(x: local_x, y: local_y)
            on_up(x: local_x, y: local_y)
          end
        end
      end
    end
  end
end

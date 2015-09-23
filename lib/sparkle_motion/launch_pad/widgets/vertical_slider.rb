module SparkleMotion
  module LaunchPad
    module Widgets
      # Class to represent a slider-style control on a Novation Launchpad.
      class VerticalSlider < Widget
        attr_accessor :on_change, :orbit

        def initialize(launchpad:, position:, size:, colors:, on_change: nil, value: 0, orbit: nil)
          super(launchpad: launchpad,
                position:  position,
                size:      Vector2.new(1, size),
                colors:    colors,
                value:     value)
          @orbit     = orbit
          @on_change = on_change

          attach_orbit_handler!
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

        def attach_orbit_handler!
          return unless orbit
          xx, yy = expand_range
          orbit.response_to(:grid, :down, x: xx, y: yy) do |_inter, action|
            handle_grid_response_down(action)
            # TODO: Update Launchpad lights...
          end
          orbit.response_to(:grid, :up, x: xx, y: yy) do |_inter, action|
            handle_grid_response_up(action)
            # TODO: Update Launchpad lights...
          end
        end
      end
    end
  end
end

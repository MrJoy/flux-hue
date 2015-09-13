require_relative "./toggle"

module SparkleMotion
  module LaunchPad
    module Widgets
      # Class to represent a single stateless button.
      class Button < Toggle
        def initialize(launchpad:,
                       position:,
                       colors:,
                       on_press: nil,
                       value: 0)
          super(launchpad: launchpad,
                position:  position,
                colors:    { on:   colors["color"] || colors[:color],
                             off:  colors["color"] || colors[:color],
                             down: colors["down"] || colors[:down] },
                value:     value,
                on_press:  on_press)
        end
      end
    end
  end
end

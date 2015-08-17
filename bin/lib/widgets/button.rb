require_relative "./toggle"

module Widgets
  # Class to represent a single stateless button.
  class Button < Toggle
    def initialize(launchpad:, position: nil, x: nil, y: nil, color:, down:, on_press: nil, value: 0)
      super(launchpad: launchpad, position: position, x: x, y: y, on: color, off: color, down: down, value: value, on_press: on_press)
    end
  end
end

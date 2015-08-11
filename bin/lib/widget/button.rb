module Widget
  # Class to represent a single stateless button.
  class Button < Toggle
    def initialize(launchpad:, position:, color:, down:, on_press: nil, value: 0)
      super(launchpad: launchpad, position: position, on: color, off: color, down: down, value: value, on_press: on_press)
    end
  end
end

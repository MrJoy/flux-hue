module Widget
  # Class to represent a slider-style control on a Novation Launchpad.
  class VerticalSlider < Base
    attr_accessor :on_change

    def initialize(launchpad:, x:, y:, height:, on:, off:, down:, on_change: nil, value: 0)
      super(launchpad: launchpad, x: x, y: y, width: 1, height: height, on: on, off: off, down: down, value: value)
      @on_change = on_change
    end

    def render
      (0..max_v).each do |yy|
        change_grid(x: 0, y: yy, color: (value >= yy) ? on : off)
      end
      super
    end

  protected

    def on_down(x:, y:)
      @value = y
      super(x: x, y: y)
      on_change.call(value) if on_change
    end
  end
end

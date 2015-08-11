module Widget
  # Class to represent a slider-style control on a Novation Launchpad.
  class VerticalSlider < Base
    attr_accessor :on_change

    def initialize(launchpad:, x:, y:, height:, on:, off:, down:, on_change: nil, value: 0)
      super(launchpad: launchpad, x: x, y: y, width: 1, height: height, on: on, off: off, down: down, value: value)
      @max_v      = height - 1
      @on_change  = on_change

      @launchpad.response_to(:grid, :both, x: @x, y: (@y..max_y)) do |inter, action|
        guard_call("VerticalSlider(#{@x},#{@y})") do
          xx = action[:x]
          yy = action[:y]
          if action[:state] == :down
            update(yy - @y, false)
            change_grid(xx - @x, yy - @y, down)
            on_change.call(value) if on_change
          else
            render
          end
        end
      end
    end

    def render
      val = value
      val = @max_v if val >= height
      (0..val).each do |yy|
        change_grid(x: 0, y: yy, color: on)
      end
      ((val+1)..@max_v).each do |yy|
        change_grid(x: 0, y: yy, color: off)
      end
    end
  end
end

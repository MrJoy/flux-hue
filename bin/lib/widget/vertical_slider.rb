module Widget
  # Class to represent a slider-style control on a Novation Launchpad.
  class VerticalSlider < Base
    attr_accessor :on_change
    attr_reader :value

    def initialize(launchpad:, x:, y:, height:, on:, off:, down:, on_change: nil, value: 0)
      super(launchpad: launchpad, x: x, y: y, on: on, off: off, down: down)
      @height     = height
      @max_v      = height - 1
      @value      = value
      @on_change  = on_change

      @launchpad.response_to(:grid, :both, x: @x, y: (@y..(@y + @max_v))) do |inter, action|
        guard_call("VerticalSlider(#{@x},#{@y})") do
          xx = action[:x]
          yy = action[:y]
          if action[:state] == :down
            update(yy - @y)
            inter.device.change_grid(xx, yy, @down[:r], @down[:g], @down[:b])
            @on_change.call(@value) if @on_change
          else
            render
          end
        end
      end
    end

    def render
      val = @value
      val = @height - 1 if val >= @height
      (0..@value).each do |yy|
        @launchpad.device.change_grid(@x, @y + yy, @on[:r], @on[:g], @on[:b])
      end
      ((val+1)..@max_v).each do |yy|
        @launchpad.device.change_grid(@x, @y + yy, @off[:r], @off[:g], @off[:b])
      end
    end
  end
end

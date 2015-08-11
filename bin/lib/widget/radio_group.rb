module Widget
  # Class to represent a radio-button group control on a Novation Launchpad.
  class RadioGroup < Base
    attr_accessor :on_select
    attr_reader :value

    def initialize(launchpad:, x:, y:, width:, height:, on:, off:, down:, on_select: nil, on_deselect:, value: nil)
      super(launchpad: launchpad, x: x, y: y, on: on, off: off, down: down)
      @height       = height
      @width        = width
      @max_v        = (height * width) - 1
      @value        = value
      @on_select    = on_select
      @on_deselect  = on_deselect

      @launchpad.response_to(:grid, :both, x: (@x..(@x + @width - 1)), y: (@y..(@y + @height - 1))) do |inter, action|
        guard_call("RadioGroup(#{@x},#{@y})") do
          xx = action[:x]
          yy = action[:y]
          vv = (yy * @width) + xx
          if action[:state] == :down
            if @value == vv
              clear!
            else
              update(vv)
            end
            inter.device.change_grid(xx, yy, @down[:r], @down[:g], @down[:b])
            (@value ? @on_select : @on_deselect).call(@value) if @on_select
          else
            render
          end
        end
      end
    end

    def clear!
      @value = nil
      render
    end

    def render
      val = @value
      val = @max_v if val && val >= @max_v
      (0..(@width - 1)).each do |xx|
        (0..(@height - 1)).each do |yy|
          l_val = (yy * @width) + xx
          if @value == l_val
            col = @on
          else
            col = @off
          end

          @launchpad.device.change_grid(@x + xx, @y + yy, col[:r], col[:g], col[:b])
        end
      end
    end
  end
end

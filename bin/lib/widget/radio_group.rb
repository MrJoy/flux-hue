module Widget
  # Class to represent a radio-button group control on a Novation Launchpad.
  class RadioGroup < Base
    attr_accessor :on_select, :on_deselect

    def initialize(launchpad:, x:, y:, width:, height:, on:, off:, down:, on_select: nil, on_deselect:, value: nil)
      super(launchpad: launchpad, x: x, y: y, width: width, height: height, on: on, off: off, down: down, value: value)
      @max_v        = (height * width) - 1
      @on_select    = on_select
      @on_deselect  = on_deselect

      @launchpad.response_to(:grid, :both, x: (@x..(@x + @width - 1)), y: (@y..(@y + @height - 1))) do |inter, action|
        guard_call("RadioGroup(#{@x},#{@y})") do
          xx = action[:x]
          yy = action[:y]
          vv = (yy * @width) + xx
          if action[:state] == :down
            if @value == vv
              clear!(false)
            else
              update(vv, false)
            end
            change_grid(x: xx - @x, y: yy - @y, color: down)
            (value ? on_select : on_deselect).call(value) if on_select
          else
            render
          end
        end
      end
    end

    def clear!(render_now = true)
      @value = nil
      render if render_now
    end

    def render
      val = value
      val = @max_v if val && val >= @max_v
      (0..max_x).each do |xx|
        (0..max_y).each do |yy|
          col = (value == value_for(x: xx, y: yy)) ? on : off

          change_grid(x: x + xx, y: y + yy, color: col)
        end
      end
    end

  protected

    def value_for(x:, y:); (y * width) + x; end
  end
end

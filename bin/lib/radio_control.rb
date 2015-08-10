# Class to represent a radio-button group control on a Novation Launchpad.
class RadioControl
  attr_accessor :on_select
  attr_reader :value

  def initialize(launchpad:, x:, y:, width:, height:, on:, off:, down:, on_select: nil, value: nil)
    @x          = x
    @y          = y
    @height     = height
    @width      = width
    @max_v      = (height * width) - 1
    @on         = BarControl::BLACK.merge(on)
    @off        = BarControl::BLACK.merge(off)
    @down       = BarControl::BLACK.merge(down)
    @value      = value
    @on_select  = on_select
    @launchpad  = launchpad

    @launchpad.response_to(:grid, :both, x: (@x..(@x + @width - 1)), y: (@y..(@y + @height - 1))) do |inter, action|
      guard_call("RadioControl(#{@x},#{@y})") do
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
          @on_select.call(@value) if @on_select
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

  def update(value)
    @value = value
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

module Widget
  class Base
    # TODO: Way of enforcing color limits...
    BLACK = { r: 0,    g: 0,    b: 0    }.freeze
    WHITE = { r: 0x3F, g: 0x3F, b: 0x3F }.freeze

    attr_reader :value, :x, :y, :width, :height
    attr_accessor :on, :off, :down

    # TODO: Use `Vector2` for position/size...
    def initialize(launchpad:, x:, y:, width:, height:, on:, off:, down:, value:)
      @x          = x
      @y          = y
      @width      = width
      @height     = height
      @on         = BLACK.merge(on)
      @off        = BLACK.merge(off)
      @down       = BLACK.merge(down)
      @launchpad  = launchpad
      @value      = value
      @pressed    = {}

      @launchpad.response_to(:grid, :both, x: (@x..(@x + max_x)), y: (@y..(@y + max_y))) do |inter, action|
        guard_call("#{self.class.name}(#{@x},#{@y})") do
          xx  = action[:x] - @x
          yy  = action[:y] - @y
          idx = index_for(x: xx, y: yy)
          if action[:state] == :down
            @pressed[idx] = true
            on_down(x: xx, y: yy)
          else
            @pressed.delete(idx) if @pressed.key?(idx)
            on_up(x: xx, y: yy)
          end
        end
      end
    end

    def update(value, render_now = true)
      @value = value
      @value = max_v if max_v && @value && @value > max_v
      render if render_now
    end

    def render
      @pressed.map do |idx, value|
        next unless value
        xx, yy = coords_for(idx: idx)
        change_grid(x: xx, y: yy, color: down)
      end
    end

  protected

    attr_reader :launchpad

    def index_for(x:, y:); (y * width) + x; end
    def coords_for(idx:); [idx / width, idx % width]; end

    # Defaults that you may want to override:
    def max_v; @max_v ||= (height * width) - 1; end
    def on_down(x:, y:); change_grid(x: x, y: y, color: down); end
    def on_up(x:, y:); render; end

    # Internal utilities for you to use:
    def change_grid(x:, y:, color:)
      return if (x > max_x) || (x < 0)
      return if (y > max_y) || (y < 0)
      launchpad.device.change_grid(x + @x, y + @y, color[:r], color[:g], color[:b])
    end

    def max_y; @max_y ||= height - 1; end
    def max_x; @max_x ||= width - 1; end
  end
end

module Widget
  class Base
    BLACK = { r: 0,    g: 0,    b: 0    }.freeze
    WHITE = { r: 0x3F, g: 0x3F, b: 0x3F }.freeze

    # TODO: Use `Vector2` for position/size...
    def initialize(launchpad:, x:, y:, on:, off:, down:)
      @x          = x
      @y          = y
      @on         = BLACK.merge(on)
      @off        = BLACK.merge(off)
      @down       = BLACK.merge(down)
      @launchpad  = launchpad
    end

    def update(value)
      @value = value
      render
    end
  end
end

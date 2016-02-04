module SparkleMotion
  module LaunchPad
    # Color classes for the Novation Launchpad Mk 2, which supports 4 bits per
    # color element in RGB mode.
    class Color
      attr_reader :r, :g, :b
      def initialize(r, g, b)
        @r = clamp_elem(r)
        @g = clamp_elem(g)
        @b = clamp_elem(b)
      end

      def to_h
        { r: r,
          g: g,
          b: b }
      end

    protected

      def clamp_elem(elem)
        return 0x00 if elem < 0x00
        return 0x3F if elem > 0x3F # 63
        elem
      end
    end

    #
    class Color
      BLACK       = new(0x00, 0x00, 0x00).freeze
      DARK_GRAY   = new(0x07, 0x07, 0x07).freeze
      LIGHT_GRAY  = new(0x27, 0x27, 0x27).freeze
      WHITE       = new(0x3F, 0x3F, 0x3F).freeze
      DARK_RED    = new(0x07, 0x00, 0x00).freeze
      RED         = new(0x3F, 0x00, 0x00).freeze
      LIGHT_RED   = new(0x3F, 0x10, 0x10).freeze
      DARK_GREEN  = new(0x00, 0x07, 0x00).freeze
      GREEN       = new(0x00, 0x3F, 0x00).freeze
      LIGHT_GREEN = new(0x10, 0x4F, 0x10).freeze
      BLUE        = new(0x00, 0x00, 0x3F).freeze
      LIGHT_BLUE  = new(0x10, 0x10, 0x3F).freeze
    end
  end
end

# Helper functionality around colors.
module Color
  # Color classes for the Novation Launchpad, which supports 4 bits per color
  # element.
  module LaunchPad
    # An RGB-space color for the Novation Launchpad.
    class RGBColor
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
        return 0 if elem < 0
        return 63 if elem > 63
        elem
      end
    end

    BLACK       = RGBColor.new(0x00, 0x00, 0x00).freeze
    DARK_GRAY   = RGBColor.new(0x0F, 0x0F, 0x0F).freeze
    LIGHT_GRAY  = RGBColor.new(0x27, 0x27, 0x27).freeze
    WHITE       = RGBColor.new(0x3F, 0x3F, 0x3F).freeze
    RED         = RGBColor.new(0x3F, 0x00, 0x00).freeze
    GREEN       = RGBColor.new(0x00, 0x3F, 0x00).freeze
    BLUE        = RGBColor.new(0x00, 0x00, 0x3F).freeze
  end
end

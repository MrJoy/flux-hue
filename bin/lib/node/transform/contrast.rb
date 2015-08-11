module Node
  module Transform
    # Transform values from 0..1 into a new range.
    class Contrast < Base
      def initialize(function:, iterations:, source:, mask: nil)
        super(source: source, mask: mask)
        @contrast = Perlin::Curve.contrast(function, iterations)
      end

      def update(t)
        super(t) do |x|
          @contrast.call(@source[x])
        end
      end
    end
  end
end

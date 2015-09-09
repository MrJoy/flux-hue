module Nodes
  module Transforms
    # Transform values from 0..1 into a new range.
    class Contrast < Transform
      def initialize(function:, iterations:, source:, mask: nil)
        super(source: source, mask: mask)
        function  = Perlin::Curve.const_get(function.to_s.upcase)
        @contrast = Perlin::Curve.contrast(function, iterations.to_i)
      end

      def update(t)
        super(t) do |x|
          @contrast.call(@source[x])
        end
      end
    end
  end
end

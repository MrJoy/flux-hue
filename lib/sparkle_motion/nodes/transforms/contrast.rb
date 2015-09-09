module SparkleMotion
  module Nodes
    module Transforms
      # Transform values from 0..1 into a new range.
      class Contrast < Transform
        attr_accessor :function, :iterations

        def function=(val)
          function  = Perlin::Curve.const_get(val.to_s.upcase)
          @contrast = Perlin::Curve.contrast(function, @iterations.to_i)
        end

        def update(t)
          super(t) do |x|
            @contrast.call(@source[x])
          end
        end
      end
    end
  end
end

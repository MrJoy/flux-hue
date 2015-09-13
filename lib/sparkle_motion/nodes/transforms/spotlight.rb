module SparkleMotion
  module Nodes
    module Transforms
      # Spotlight a particular point on the line.
      #
      # TODO: Integrate the underlying light value but ensure we contrast-stretch
      # TODO: to ensure a bright-enough spotlight over the destination.  Maybe a LERP?
      #
      # TODO: Allow effect to come in / go out over time.
      #
      # TODO: Parameterize the falloff
      class Spotlight < Transform
        def initialize(source:, base:, exponent:, mask: nil)
          super(source: source, mask: mask)
          @spotlight  = nil
          @base       = base
          @exponent   = exponent
        end

        def spotlight!(x)
          @spotlight = x
        end

        def update(t)
          super(t) do |x|
            val = @source[x]
            if @spotlight
              falloff   = @base**((@spotlight - x).abs**@exponent)
              val       = falloff
            end
            val
          end
        end
      end
    end
  end
end

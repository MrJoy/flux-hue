module SparkleMotion
  module Nodes
    module Transforms
      # Joins lanes from various other nodes.
      class Join < Transform
        # Helper to wedge our desired behavior in.
        class RemapNodes
          def initialize(sources)
            @source = sources
            # TODO: Implement me.  Bleah.
            @offset = 0
            @size   = sources[0].lights #.map(&:lights).inject(:+)
          end

          def [](x); @source[0][x + @offset]; end

          def update(t)
            @source.first.update(t)
          end

          def lights; @size; end
        end

        def initialize(sources:)
          super(source: RemapNodes.new(sources))
        end

        def update(t)
          super(t) do |x|
            @source[x]
          end
        end
      end
    end
  end
end

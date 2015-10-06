module SparkleMotion
  module Nodes
    module Transforms
      # Slices a subset of lanes from a source.
      class Slice < Transform
        # Helper to wedge our desired behavior in.
        class RemapNode
          def initialize(source, range)
            @source = source
            @offset = range.first
            @size   = range.size
          end

          def [](x); @source[x + @offset]; end

          def lights; @size; end

          def update(t)
            @source.update(t)
          end
        end

        def initialize(range:, source:)
          super(source: RemapNode.new(source, range))
          @range = range
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

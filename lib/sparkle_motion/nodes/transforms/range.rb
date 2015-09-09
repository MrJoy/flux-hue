module SparkleMotion
  module Nodes
    module Transforms
      # Transform values from 0..1 into a new range.
      #
      # TODO: Allow change to range to apply over time.
      class Range < Transform
        def initialize(initial_min:, initial_max:, source:, mask: nil)
          super(source: source, mask: mask)
          @min = initial_min
          @max = initial_max
        end

        def update(t)
          super(t) do |x|
            (@source[x] * (@max - @min)) + @min
          end
        end

        def set_range(new_min, new_max)
          @min = new_min
          @max = new_max
        end
      end
    end
  end
end

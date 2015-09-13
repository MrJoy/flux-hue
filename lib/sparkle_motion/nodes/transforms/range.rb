module SparkleMotion
  module Nodes
    module Transforms
      # Transform values from 0..1 into a new range.
      #
      # TODO: Allow change to range to apply over time?
      class Range < Transform
        def initialize(source:, mask: nil, logger:)
          super(source: source, mask: mask)
          @logger   = logger
          @min      = 0.0
          @max      = 1.1
        end

        def update(t)
          super(t) do |x|
            (@source[x] * (@max - @min)) + @min
          end
        end

        def set_range(mid_point, delta)
          @min = clamp("min", mid_point, delta, mid_point - delta)
          @max = clamp("max", mid_point, delta, mid_point + delta)
        end

      protected

        def clamp(name, mid_point, delta, val)
          if val < 0
            @logger.warn { "Bad range [#{mid_point} +/- #{delta}] - #{name} was <0! (#{val})" }
            val = 0
          end
          if val > 1.0
            @logger.warn { "Bad range [#{mid_point} +/- #{delta}] - #{name} was >1! (#{val})" }
            val = 1.0
          end
          val
        end
      end
    end
  end
end

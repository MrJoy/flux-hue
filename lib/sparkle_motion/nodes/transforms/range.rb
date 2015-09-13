module SparkleMotion
  module Nodes
    module Transforms
      # Transform values from 0..1 into a new range.
      #
      # TODO: Allow change to range to apply over time?
      class Range < Transform
        def initialize(mid_point:, delta:, source:, mask: nil, logger:)
          super(source: source, mask: mask)
          @logger = logger
          set_range(mid_point, delta)
        end

        def update(t)
          super(t) do |x|
            (@source[x] * (@max - @min)) + @min
          end
        end

        def set_range(mid_point, delta)
          @min = clamp("min", mid_point, delta, (mid_point - delta).round)
          @max = clamp("max", mid_point, delta, (mid_point + delta).round)
        end

      protected

        def clamp(name, mid_point, delta, val)
          if val < 0
            @logger.warn { "Bad range [#{mid_point} +/- #{delta}] - #{name} was <0! (#{val})" }
            val = 0
          end
          if val > 255
            @logger.warn { "Bad range [#{mid_point} +/- #{delta}] - #{name} was >255! (#{val})" }
            val = 255
          end
          val
        end
      end
    end
  end
end

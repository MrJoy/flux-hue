module SparkleMotion
  module Nodes
    module Transforms
      # Transform values from 0..1 into a new range.
      #
      # TODO: Allow change to range to apply over time?
      class Range < Transform
        def initialize(source:, logger:)
          super(source: source)
          @logger       = logger
          @clamp_to     = nil
          @clamp_target = nil
          @min          = 0.0
          @max          = 1.1
        end

        def update(t)
          eff_min = @clamp_target || @min
          eff_max = @clamp_target || @max
          super(t) do |x|
            (@source[x] * (eff_max - eff_min)) + eff_min
          end
        end

        def clamp_to(val)
          @clamp_to = val
          recompute_clamp_target!
        end

        def set_range(mid_point, delta)
          @min = clamp("min", mid_point, delta, mid_point - delta)
          @max = clamp("max", mid_point, delta, mid_point + delta)
          recompute_clamp_target!
        end

      protected

        def recompute_clamp_target!
          @clamp_target = nil
          return unless @clamp_to

          @clamp_target = [@min, @max, @clamp_to].compact.sort.first
        end

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

module SparkleMotion
  module Nodes
    # A sub-class of `Node` for any node that operates as a transform, rather than as a root node.
    #
    # Sub-classes should override `update(t)` and call it like so:
    #
    # ```ruby
    # def update(t)
    #   super(t) do |x|
    #     # calculate value for light `x` from `@source[x]` here.
    #   end
    # end
    # ```
    class Transform < Node
      def initialize(source:, lights: nil)
        super(lights: lights || source.lights)
        @source = source
      end

      def update(t)
        @source.update(t)
        if block_given?
          (0..(@lights - 1)).each do |x|
            # Apply to all lights if no mask, and apply to specific lights if mask.
            @state[x] = yield(x)
          end
        end
        super(t)
      end
    end
  end
end

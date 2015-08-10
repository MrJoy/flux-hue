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
class TransformNode < Node
  def initialize(lights:, source: nil, debug: false)
    super(lights: lights, debug: debug)
    @source = source
  end

  def update(t)
    @source.update(t)
    if block_given?
      (0..(@lights - 1)).each do |x|
        @state[x] = yield(x)
      end
    end
    super(t)
  end
end

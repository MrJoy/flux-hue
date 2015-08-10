# A sub-class of `Node` for any node that operates as a transform, rather than as a root node.
class TransformNode < Node
  def initialize(lights:, source: nil, debug: false)
    super(lights: lights, debug: debug)
    @source = source
  end

  def update(t)
    @source.update(t)
    yield if block_given?
    super(t)
  end
end

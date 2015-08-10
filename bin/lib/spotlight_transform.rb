# Spotlight a particular point on the line.
#
# TODO: Integrate the underlying light value but ensure we contrast-stretch
# TODO: to ensure a bright-enough spotlight over the destination.  Maybe a LERP?
class SpotlightTransform < TransformNode
  def initialize(lights:, source:, debug: false)
    super(lights: lights, source: source, debug: debug)
    @spotlight  = nil
  end

  def spotlight(x)
    @spotlight = x
  end

  def clear!; @spotlight = nil; end

  def update(t)
    super(t) do |x|
      val = @source[x]
      if @spotlight
        distance = (@spotlight - x).abs
        falloff = 0.9 ** (distance ** 3)
        val = falloff
      end
      val
    end
  end
end

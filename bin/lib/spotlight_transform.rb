# Spotlight a particular point on the line.
#
# TODO: Integrate the underlying light value but ensure we contrast-stretch
# TODO: to ensure a bright-enough spotlight over the destination.  Maybe a LERP?
#
# TODO: Allow effect to come in / go out over time.
class SpotlightTransform < TransformNode
  def initialize(source:, mask: nil)
    super(source: source, mask: mask)
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
        falloff   = 0.9 ** ((@spotlight - x).abs ** 3)
        val       = falloff
      end
      val
    end
  end
end

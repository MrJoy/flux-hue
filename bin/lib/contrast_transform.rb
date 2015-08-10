# Transform values from 0..1 into a new range.
class ContrastTransform < TransformNode
  def initialize(function:, iterations:, source:)
    super(source: source)
    @contrast = Perlin::Curve.contrast(function, iterations)
  end

  def update(t)
    super(t) do |x|
      @contrast.call(@source[x])
    end
  end
end

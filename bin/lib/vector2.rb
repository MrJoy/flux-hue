# A 2-component vector, where components go from 0.0..1.0.
class Vector2
  attr_reader :x, :y
  def initialize(x: 0.0, y: 0.0)
    @x = x
    @y = y
  end
end

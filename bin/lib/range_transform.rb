# Transform values from 0..1 into a new range.
class RangeTransform < TransformNode
  def initialize(lights:, initial_min:, initial_max:, source:, debug: false)
    super(lights: lights, source: source, debug: debug)
    @min = initial_min
    @max = initial_max
  end

  def [](x); (@source[x] * (@max - @min)) + @min; end

  def update(t)
    super(t) do
      (0..(@lights - 1)).each do |n|
        @state[n] = (@source[n] * (@max - @min)) + @min
      end
    end
  end

  def set_range(new_min, new_max)
    @min = new_min
    @max = new_max
  end
end

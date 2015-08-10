# Transform values from 0..1 into a new range.
class RangeTransform
  def initialize(initial_min:, initial_max:, source:)
    @min  = initial_min
    @max  = initial_max
    @source       = source
  end

  def [](x)
    (@source[x] * (@max - @min)) + @min
  end

  def set_range(new_min, new_max)
    @min = new_min
    @max = new_max
  end
end

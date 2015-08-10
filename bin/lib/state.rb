FRAME_PERIOD  = 0.01
DEBUG_SCALE   = Vector2.new(x: 2, y: 1)

# Generalized representation for the state of an ordered set of lights.
class State
  attr_accessor :history

  def initialize(lights:, initial_state: nil, debug: false)
    @debug    = debug
    @history  = [] if @debug
    @lights   = lights
    @state    = Array.new(@lights)
    lights.times do |n|
      @state[n] = initial_state ? initial_state[n] : 0.0
    end
  end

  def [](n); @state[n]; end
  def []=(n, val); @state[n] = val; end

  def update(t)
    return unless @debug
    prev_t  = @history.last
    prev_t  = prev_t ? prev_t[:t] : t
    delta   = t - prev_t
    @history << { t: t, dt: delta, state: @state.dup }
  end

  def snapshot_to!(fname)
    enrich_history!
    png = new_image
    history.inject(0) do |y, snapshot|
      next_y = y + snapshot[:y]
      colors = snapshot[:state].map { |z| to_color(z) }
      (y..(next_y - 1)).each do |yy|
        colors.each_with_index do |c, x|
          x1 = (x * DEBUG_SCALE.x).to_i
          x2 = ((x + 1) * DEBUG_SCALE.x).to_i - 1
          (x1..x2).each do |xx|
            png[xx, yy] = c
          end
        end
      end
      next_y
    end
    png.save(fname, interlace: false)
  end

protected

  def new_image
    ChunkyPNG::Image.new((@lights * DEBUG_SCALE.x).to_i,
                         history.map { |sn| sn[:y] }.inject(0) { |x, y| x + y },
                         ChunkyPNG::Color::TRANSPARENT)
  end

  def enrich_history!
    @history.each do |snapshot|
      frames       = snapshot[:dt] * (1 / FRAME_PERIOD) # A "frame" == 10ms.
      elapsed      = (frames * DEBUG_SCALE.y).round.to_i
      snapshot[:y] = (elapsed > 0) ? elapsed : DEBUG_SCALE.y.to_i
    end
  end

  def to_color(val)
    # Based on precision of Hue API...
    z = (val * 254).to_i
    ChunkyPNG::Color.rgba(z, z, z, 255)
  end
end

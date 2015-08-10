FRAME_PERIOD  = 0.04
DEBUG_SCALE   = Vector2.new(x: 2, y: 1)

# Base class representing the state of an ordered set of lights, with an ability to debug
# things via PNG dump.
class Node
  attr_accessor :history, :debug, :lights

  def initialize(lights:)
    @lights   = lights
    @state    = Array.new(@lights)
    lights.times do |n|
      @state[n] = 0.0
    end
  end

  def debug=(val)
    @debug = val
    @history ||= [] if @debug
  end

  def [](n); @state[n]; end
  def []=(n, val); @state[n] = val; end

  def update(t)
    return unless @debug
    prev_t  = @history.last
    prev_t  = prev_t ? prev_t[:t] : t
    @history << { t:     t,
                  dt:    t - prev_t,
                  state: (0..(@lights - 1)).map { |n| self[n] } }
  end

  def snapshot_to!(fname)
    enrich_history!
    png = new_image
    history.inject(0) do |y, snapshot|
      next_y = y + (snapshot[:y] || 0)
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
                         history.map { |sn| sn[:y] }.inject(0) { |x, y| (x || 0) + y },
                         ChunkyPNG::Color::TRANSPARENT)
  end

  def enrich_history!
    @history.each do |snapshot|
      frames       = snapshot[:dt] * (1 / FRAME_PERIOD) # A "frame" == fixed update interval in ms.
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

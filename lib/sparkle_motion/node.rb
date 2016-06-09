module SparkleMotion
  # Base class representing the state of an ordered set of lights, with an ability to debug
  # things via PNG dump.
  class Node
    FRAME_PERIOD  = 0.04
    DEBUG_SCALE   = Vector2.new(2, 6)

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
      history.each_with_index do |snapshot, y|
        next if y == 0
        last_snapshot = history[y - 1][:state]
        y0 = (y - 1) * DEBUG_SCALE.y
        y1 = (y0 + DEBUG_SCALE.y) - 1
        yy0 = y0
        yy1 = y1
        y0 = y0.to_f
        y1 = y1.to_f
        (yy0..yy1).each do |yy|
          yy = yy.to_f
          snapshot[:state].each_with_index do |c1, x|
            c0 = last_snapshot[x]
            x0 = (x * DEBUG_SCALE.x).to_i
            x1 = ((x + 1) * DEBUG_SCALE.x).to_i - 1
            (x0..x1).each do |xx|
              begin
                c = c0 * (1 - ((yy - y0) / (y1 - y0))) +
                    c1 * (1 - ((y1 - yy) / (y1 - y0)))
                # puts "[#{y0}..#{y1}] #{xx}x#{yy} == #{c}"
                png[xx, yy.to_i] = to_color(c)
              rescue FloatDomainError
                puts "GAH!  Got: #{c.inspect} from y0=#{y0}, y1=#{y1}, yy=#{yy}, c0=#{c0}, c1=#{c1}"
              end
            end
          end
        end
      end
      png.save(fname, interlace: false)
    end

  protected

    def new_image
      require "oily_png" unless defined?(::ChunkyPNG)
      ChunkyPNG::Image.new((@lights * DEBUG_SCALE.x).to_i,
                           (history.length - 1) * DEBUG_SCALE.y,
                           ChunkyPNG::Color::TRANSPARENT)
    end

    def enrich_history!
      @history.each do |snapshot|
        frames       = snapshot[:dt] * (1 / FRAME_PERIOD) # A "frame" == fixed update interval, ms.
        elapsed      = (frames * DEBUG_SCALE.y).round.to_i
        snapshot[:y] = (elapsed > 0) ? elapsed : DEBUG_SCALE.y.to_i
      end
    end

    def to_color(val)
      # Based on precision of Hue API...
      z = (val * 255).round
      z = 255 if z > 255
      ChunkyPNG::Color.rgba(z, z, z, 255)
    end
  end
end

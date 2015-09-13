module SparkleMotion
  # A 2-component vector, with numeric components.
  class Vector2
    attr_reader :x, :y
    def initialize(*args)
      args  = args.first if args.first.is_a?(Array)
      @x    = args[0]
      @y    = args[1]
    end

    def width; @x; end
    def height; @y; end

    def to_s; "<<#{@x}, #{@y}>>"; end

    ZERO = Vector2.new(0, 0)
    ONE  = Vector2.new(1, 1)
  end
end

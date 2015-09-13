module SparkleMotion
  # A 2-component vector, where components go from 0.0..1.0.
  class Vector2
    attr_reader :x, :y
    def initialize(*args)
      puts args.inspect
      args = args.first if args.first.is_a?(Array)
      @x = args[0]
      @y = args[1]
    end

    def to_s; "<<#{@x}, #{@y}>>"; end
  end
end

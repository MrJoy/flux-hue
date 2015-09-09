module SparkleMotion
  module Nodes
    module Generators
      # Manage and run a simulation of just `sin(x + y)`.
      class Wave2 < Generator
        def initialize(lights:, speed:)
          super(lights: lights)
          @speed = speed
        end

        def update(t)
          @lights.times do |n|
            self[n] = (Math.sin((n * @speed.x) + (t * @speed.y)) * 0.5) + 0.5
          end
          super(t)
        end
      end
    end
  end
end

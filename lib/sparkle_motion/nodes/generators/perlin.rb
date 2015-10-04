module SparkleMotion
  module Nodes
    module Generators
      # Manage and run a Perlin-noise based simulation.
      #
      # TODO: Play with octaves / persistence, etc.
      class Perlin < Generator
        def initialize(lights:, speed:)
          super(lights: lights)
          @speed  = speed
          # TODO: See if we need/want to tinker with the `interval` option...
          @perlin = ::Perlin::Noise.new(2, seed: 0)
        end

        def update(t)
          @lights.times do |n|
            self[n] = @perlin[n * @speed.x, t * @speed.y]
          end
          super(t)
        end
      end
    end
  end
end

# Manage and run a Perlin-noise based simulation.
#
# TODO: Play with octaves / persistence, curves, etc.
class PerlinSimulation < State
  def initialize(lights:, initial_state: nil, seed:, speed:, debug: false)
    super(lights: lights, initial_state: initial_state, debug: debug)
    @speed      = speed
    # TODO: If we just cheat and use a fixed seed, that should be totally fine
    # TODO: and make resumability much simpler.
    #
    # TODO: Perlin::Noise also supports interval and curve options...
    @perlin     = Perlin::Noise.new(2, seed: seed)
    @contrast   = Perlin::Curve.contrast(Perlin::Curve::CUBIC, 3)
  end

  def update(t)
    @lights.times do |n|
      self[n] = @contrast.call(@perlin[n * @speed.x, t * @speed.y])
    end
    super(t)
  end
end

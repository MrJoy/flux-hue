# Manage and run a Perlin-noise based simulation.
#
# TODO: Play with octaves / persistence, curves, etc.
class Wave2Simulation < RootNode
  def initialize(lights:, initial_state: nil, speed:, debug: false)
    super(lights: lights, initial_state: initial_state, debug: debug)
    @speed      = speed
  end

  def update(t)
    @lights.times do |n|
      self[n] = (Math.sin((n * @speed.x) + (t * @speed.y)) * 0.5) + 0.5
    end
    super(t)
  end
end

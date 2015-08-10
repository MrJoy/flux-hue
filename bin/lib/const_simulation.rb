# For debugging, output 1.0 all the time.
class ConstSimulation < RootNode
  def initialize(lights:, debug: false)
    super(lights: lights, initial_state: nil, debug: debug)
  end

  def update(t)
    @lights.times do |n|
      self[n] = 1.0
    end
    super(t)
  end
end

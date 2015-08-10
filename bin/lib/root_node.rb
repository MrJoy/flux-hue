# A sub-class of `Node` for any node that operates as the root of a DAG, rather than as a transform.
class RootNode < Node
  def initialize(lights:, initial_state: nil, debug: false)
    super(lights: lights, debug: debug)
    lights.times do |n|
      @state[n] = initial_state ? initial_state[n] : 0.0
    end
  end
end

module Nodes
  # A sub-class of `Node` for any node that operates as the root of a DAG, rather than as a
  # transform.
  class Generator < Node
    def initialize(lights:, initial_state: nil)
      super(lights: lights)
      lights.times do |n|
        @state[n] = initial_state ? initial_state[n] : 0.0
      end
    end
  end
end

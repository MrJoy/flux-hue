module Node
  module Simulation
    # For debugging, output 1.0 all the time.
    class Const < Base
      def update(t)
        @lights.times do |n|
          self[n] = 1.0
        end
        super(t)
      end
    end
  end
end

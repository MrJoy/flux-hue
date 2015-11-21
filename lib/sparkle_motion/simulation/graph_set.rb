module SparkleMotion
  module Simulation
    # Manages a set of `GraphTask`s, and provides a simple DSL for defining them.
    class GraphSet
      def initialize(logger)
        @logger = logger
        @graphs = {}
      end

      def draw(&callback)
        instance_eval(&callback)
      end

      def start
        @graphs.values.map(&:start)
      end

      def stop
        @graphs.values.map(&:stop)
      end

      class Graph
        def initialize(name, logger)
          @name         = name
          @nodes        = {}
          @logger       = logger
          @task         = SparkleMotion::Simulation::GraphTask.new(name, self, 40, logger)
          @render_node  = nil
        end

        def start; @task.start; end
        def stop; @task.stop; end

        def update(t); @render_node.update(t); end
        def [](x); @render_node[x]; end

        # Generator Nodes

        def perlin(name, speed:, width:)
          @nodes[name] = SparkleMotion::Nodes::Generators::Perlin.new(lights: width,
                                                                      speed:  Vector2.new(speed))
        end

        def const(name, value:, width:)
          @nodes[name] = SparkleMotion::Nodes::Generators::Const.new(lights: width, value: value)
        end

        def wave2(name, speed:, width:)
          @nodes[name] = SparkleMotion::Nodes::Generators::Wave2.new(lights: width,
                                                                     speed:  Vector2.new(speed))
        end

        # Transformative Nodes:
        def stretch(name, function:, iterations:, from:)
          @nodes[name] = SparkleMotion::Nodes::Transforms::Contrast.new(function:   function,
                                                                        iterations: iterations,
                                                                        source:     node(from))
        end

        def remap(name, from:)
          @nodes[name] = SparkleMotion::Nodes::Transforms::Range.new(logger: @logger,
                                                                     source: node(from))
        end

        def spotlight(name, base:, exponent:, from:)
          @nodes[name] = SparkleMotion::Nodes::Transforms::Spotlight.new(base:     base,
                                                                         exponent: exponent,
                                                                         source:   node(from))
        end

        def render(name)
          @render_node = node(name)
        end

        def slice(name, range)
          SparkleMotion::Nodes::Transforms::Slice.new(range:  range,
                                                      source: node(name))
        end

        def join(*names)
          nodes = Array(names).map { |name| node(name) }
          # TODO: Implement me here...
          SparkleMotion::Nodes::Transforms::Join.new(sources: nodes)
        end

        def node(name)
          case name
          when Node then name
          else
            @nodes.fetch(name)
          end
        end

        def draw(&callback)
          instance_eval(&callback)
        end
      end

      def [](name); @graphs[name]; end

      def graph(name, &callback)
        graph = Graph.new(name, @logger)
        @graphs[name] = Graph.new(name, @logger)
        @graphs[name].draw(&callback)
      end
    end
  end
end

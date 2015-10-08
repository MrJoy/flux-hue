module SparkleMotion
  module Simulation
    # Task to render to lights more or less as quickly as feasibl.
    class RenderTask < SparkleMotion::ManagedTask
      include SparkleMotion::Hue::HTTP

      def initialize(node:, bridge:, lights:, transition:, global_results:, logger:, debug: false)
        @node           = node
        @bridge         = bridge
        @lights         = lights
        @transition     = transition
        @data           = with_transition_time(@transition, "bri" => 0)
        @global_results = global_results
        @stats          = SparkleMotion::Results.new(logger: LOGGER) if @global_results
        @debug          = debug
        # TODO: Restore ITERATIONS functionality...
        super("RenderTask[#{bridge['name']}]", :early, logger) { render }
        @requests = @lights.map { |(idx, lid)| light_req(idx, lid) }
      end

      def render
        unless USE_LIGHTS
          sleep 0.05 * @requests.length
          return
        end
        Curl::Multi.http(@requests.dup, SparkleMotion::Hue::HTTP::MULTI_OPTIONS) do
        end
        return unless @global_results
        @global_results.add_from(@stats)
        @stats.clear!
      end

    protected

      def light_req(idx, lid)
        url = hue_light_endpoint(@bridge, lid)
        SparkleMotion::Hue::LazyRequestConfig.new(@logger, @bridge, :put, url, @stats,
                                                  debug: @debug) do
          @data["bri"] = (@node[idx] * 255).round
          @data
        end
      end
    end
  end
end

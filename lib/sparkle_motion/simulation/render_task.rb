module SparkleMotion
  module Simulation
    # Task to render to lights more or less as quickly as feasibl.
    class RenderTask < ManagedTask
      include SparkleMotion::Hue::HTTP

      def initialize(node:, bridge:, lights:, global_results:, logger:, debug: false)
        @node           = node
        @bridge         = bridge
        @lights         = lights
        @data           = { "bri" => 0 }
        @global_results = global_results
        @stats          = SparkleMotion::Results.new(logger: LOGGER) if @global_results
        @debug          = debug
        @samples        = []
        @sample_idx     = 0
        @avg            = 0.0
        @requests       = @lights.map { |(idx, lid)| light_req(idx, lid) }.compact
        super("RenderTask[#{bridge['name']}]", :early, logger)
      end

      def iterate
        unless USE_LIGHTS
          sleep 0.05 * @requests.length
          return
        end
        before = Time.now.to_f
        # Curl::Multi.http(@requests.dup, SparkleMotion::Hue::HTTP::MULTI_OPTIONS) do
        # end
        @requests.dup.each do |req|
          req.delete(:put_data)
          sleep 0.045
          req.dummy!
        end
        after                 = Time.now.to_f
        elapsed               = after - before
        @samples[@sample_idx] = elapsed
        @sample_idx          += 1
        @sample_idx           = 0 if @sample_idx >= 30
        @avg                  = (@samples.inject(:+) / @samples.length.to_f).round(1)



        sleep 0.1 # <-------- ME!



        return unless @global_results
        @global_results.add_from(@stats)
        @stats.clear!
      end

    protected

      def light_req(idx, lid)
        return nil unless @node[idx]
        url = hue_light_endpoint(@bridge, lid)
        SparkleMotion::Hue::LazyRequestConfig.new(@logger, @bridge, :put, url, @stats,
                                                  debug: @debug) do
          @data["bri"] = (@node[idx] * 255).round
          with_transition_time(@avg, @data)
        end
      end
    end
  end
end

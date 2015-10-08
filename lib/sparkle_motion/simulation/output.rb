module SparkleMotion
  module Simulation
    # Helper functionality for `sm-simulate`.  Needs to be refactored like crazy of course.
    module Output
      def format_float(num); num ? num.round(2) : "-"; end

      def format_rate(rate); "#{format_float(rate)}/sec"; end

      def print_stat(name, value, rate)
        SparkleMotion.logger.unknown { "* #{value} #{name} (#{format_rate(rate)})" }
      end

      STATS = [
        ["requests",       :requests,      :requests_sec],
        ["successes",      :successes,     :successes_sec],
        ["failures",       :failures,      :failures_sec],
        ["hard timeouts",  :hard_timeouts, :hard_timeouts_sec],
        ["soft timeouts",  :soft_timeouts, :soft_timeouts_sec],
      ]

      def print_basic_stats(results)
        STATS.each do |(name, count, rate)|
          print_stat(name, results.send(count), results.send(rate))
        end
      end

      def print_other_stats(results)
        SparkleMotion.logger.unknown { "* #{format_float(results.failure_rate)}% failure rate" }
        SparkleMotion.logger.unknown { "* #{format_float(results.elapsed)} sec. elapsed" }
      end

      # TODO: Show per-bridge and aggregate stats.
      def print_results(results)
        SparkleMotion.logger.unknown { "Results:" }
        print_basic_stats(results)
        print_other_stats(results)
      end

      def dump_node_debug_data!(prefix)
        nodes_under_debug.each_with_index do |(name, node), index|
          node.snapshot_to!("tmp/%s_%02d_%s.png" % [prefix, index, name.downcase])
        end
      end

      def dump_output_debug_data!(prefix)
        return unless DEBUG_FLAGS["OUTPUT"] && USE_LIGHTS
        File.open("tmp/#{prefix}_output.raw", "w") do |fh|
          fh.write(SparkleMotion::Hue::LazyRequestConfig::GLOBAL_HISTORY.join("\n"))
          fh.write("\n")
        end
      end

      def dump_debug_data!
        return unless debugging?
        prefix = "%010.0f" % Time.now.to_f

        SparkleMotion.logger.unknown { "Dumping debug and/or profiling data to `tmp/#{prefix}_*`." }
        stop_ruby_prof!
        dump_node_debug_data!(prefix)
        dump_output_debug_data!(prefix)
      end
    end
  end
end

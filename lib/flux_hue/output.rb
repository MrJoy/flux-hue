def announce_iteration_config(iters)
  FluxHue.logger.unknown do
    if iters > 0
      "Running for #{iters} iterations."
    else
      "Running until we're killed.  Send SIGHUP to terminate with stats."
    end
  end
end

def format_float(num); num ? num.round(2) : "-"; end

def format_rate(rate); "#{format_float(rate)}/sec"; end

def print_stat(name, value, rate)
  FluxHue.logger.unknown { "* #{value} #{name} (#{format_rate(rate)})" }
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
  FluxHue.logger.unknown { "* #{format_float(results.failure_rate)}% failure rate" }
  suffix = " (#{format_float(results.elapsed / ITERATIONS.to_f)}/iteration)" if ITERATIONS > 0
  FluxHue.logger.unknown { "* #{format_float(results.elapsed)} seconds elapsed#{suffix}" }
end

# TODO: Show per-bridge and aggregate stats.
def print_results(results)
  FluxHue.logger.unknown { "Results:" }
  print_basic_stats(results)
  print_other_stats(results)
end

def dump_node_debug_data!
  nodes_under_debug.each_with_index do |(name, node), index|
    node.snapshot_to!("tmp/%s_%02d_%s.png" % [prefix, index, name.downcase])
  end
end

def dump_output_debug_data!
  return unless DEBUG_FLAGS["OUTPUT"]
  File.open("tmp/#{prefix}_output.raw", "w") do |fh|
    fh.write(LazyRequestConfig::GLOBAL_HISTORY.join("\n"))
    fh.write("\n")
  end
end

def dump_debug_data!
  return unless debugging?
  prefix = "%010.0f" % Time.now.to_f

  FluxHue.logger.unknown { "Dumping debug and/or profiling data to `tmp/#{prefix}_*`." }
  stop_ruby_prof!
  dump_node_debug_data!
  dump_output_debug_data!
end

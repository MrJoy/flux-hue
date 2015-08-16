#!/usr/bin/env ruby

# TODO: Make node structure more soft-configurable.

# TODO: Run update across nodes from back to front for simulation rather than
# TODO: relying on a call-chain.  This should make it easy to eliminate the
# TODO: `yield` usage and avoid associated allocations.

# TODO: Journal debug information to a log file, and have a separate tool to
# TODO: read that and produce PNGs.

# TODO: Journal timing info about light updates (and transition!), and use that
# TODO: to produce an "as-rendered" debug output.

# TODO: Deeper memory profiling to ensure this process can run for hours.

# TODO: When we integrate input handling and become stateful, journal state to
# TODO: a file that's read on startup so we can survive a restart.

# TODO: Pick four downlights for the dance floor, and treat them as a separate
# TODO: simulation.  Consider how spotlighting and the like will be relevant to
# TODO: them.

# TODO: Node to *clamp* brightness range so we can set the absolute limits at
# TODO: the end of the chain?  Need to consider use-cases more thoroughly.

# TODO: Tools for updating saturation on a group of lights, and a second
# TODO: range-shifting node to allow the photographer some controls.

# https://github.com/taf2/curb/tree/master/bench

#   f = Fiber.new do
#     meth(1) do
#       Fiber.yield
#     end
#   end
#   meth(2) do
#     f.resume
#   end
#   f.resume
#   p Thread.current[:name]

###############################################################################
# Early Initialization/Helpers
###############################################################################
require "rubygems"
require "bundler/setup"
Bundler.setup
require "yaml"
require "perlin_noise"
require "oily_png"
require "launchpad"

require_relative "./lib/output"
require_relative "./lib/config"
require_relative "./lib/logging"
require_relative "./lib/env"
require_relative "./lib/utility"
require_relative "./lib/results"
require_relative "./lib/http"

require_relative "./lib/node/base"
require_relative "./lib/node/simulation/base"
require_relative "./lib/node/transform/base"

require_relative "./lib/node/simulation/const"
require_relative "./lib/node/simulation/perlin"
require_relative "./lib/node/simulation/wave2"

require_relative "./lib/node/transform/contrast"
require_relative "./lib/node/transform/range"
require_relative "./lib/node/transform/spotlight"

require_relative "./lib/widget"

###############################################################################
# Profiling and Debugging
###############################################################################
PROFILE_RUN = ENV["PROFILE_RUN"]
SKIP_GC     = !!env_int("SKIP_GC")
DEBUG_FLAGS = Hash[(ENV["DEBUG_NODES"] || "")
                   .split(/\s*,\s*/)
                   .map(&:upcase)
                   .map { |nn| [nn, true] }]
USE_SWEEP   = (env_int("USE_SWEEP", true) || 1) != 0
USE_LIGHTS  = (env_int("USE_LIGHTS", true) || 1) != 0
USE_SIM     = (env_int("USE_SIM", true) || 1) != 0

###############################################################################
# Timing Configuration
#
# Play with this to see how error rates are affected.
###############################################################################
# TODO: Instead of a between sleep, we should look at how many ms we ought to
# TODO: wait after an update to avoid flooding the network.  That'll depend on
# TODO: number of components updated, etc.
SPREAD_SLEEP  = env_float("SPREAD_SLEEP") || 0.0
BETWEEN_SLEEP = env_float("BETWEEN_SLEEP") || 0.0

###############################################################################
# Effect Configuration
#
# Tweak this to change the visual effect(s).
###############################################################################
# TODO: Move all of these into the config...

WAVE2_SCALE_X   = env_float("WAVE2_SCALE_X") || 0.1
WAVE2_SCALE_Y   = env_float("WAVE2_SCALE_Y") || 1.0
WAVE2_SPEED     = Vector2.new(x: WAVE2_SCALE_X, y: WAVE2_SCALE_Y)

PERLIN_SCALE_Y  = env_float("PERLIN_SCALE_Y") || 4.0
PERLIN_SPEED    = Vector2.new(x: 0.1, y: PERLIN_SCALE_Y)

###############################################################################
# Shared State Setup
###############################################################################
# TODO: Run all simulations, and use a mixer to blend between them...
num_lights          = CONFIG["main_lights"].length
LIGHTS_FOR_THREADS  = in_groups(CONFIG["main_lights"])
INTERACTION         = Launchpad::Interaction.new(use_threads: false)
INT_STATES          = []
NODES               = {}

###############################################################################
# Simulation Graph Configuration / Setup
###############################################################################
# Root nodes (don't act as modifiers on other nodes' output):
n_cfg           = CONFIG["simulation"]["nodes"]
NODES["CONST"]  = Node::Simulation::Const.new(lights: num_lights)
NODES["WAVE2"]  = Node::Simulation::Wave2.new(lights: num_lights, speed: n_cfg["wave2"]["speed"])
NODES["PERLIN"] = Node::Simulation::Perlin.new(lights: num_lights, speed: n_cfg["perlin"]["speed"])
last            = NODES["PERLIN"]

# Transform nodes (act as a chain of modifiers):
c_cfg   = n_cfg["contrast"]
c_func  = Perlin::Curve.const_get(c_cfg["function"].upcase)
NODES["STRETCHED"] = last = Node::Transform::Contrast.new(function:   c_func,
                                                          iterations: c_cfg["iterations"],
                                                          source:     last)
# Create one control group here per "quadrant"...
intensity_cfg = CONFIG["simulation"]["controls"]["intensity"]
LIGHTS_FOR_THREADS.each_with_index do |(_bridge_name, (lights, mask)), idx|
  mask = [false] * num_lights
  lights.map(&:first).each { |ii| mask[ii] = true }

  int_vals    = intensity_cfg["values"]
  int_colors  = intensity_cfg["colors"]
  int_widget  = Kernel.const_get(intensity_cfg["widget"])
  pos         = intensity_cfg["positions"][idx]
  last        = Node::Transform::Range.new(initial_min: int_vals[0][0],
                                           initial_max: int_vals[0][1],
                                           source:      last,
                                           mask:        mask)
  INT_STATES[idx] = int_widget.new(launchpad: INTERACTION,
                                   x:         pos[0],
                                   y:         pos[1],
                                   size:      intensity_cfg["size"],
                                   on:        int_colors["on"],
                                   off:       int_colors["off"],
                                   down:      int_colors["down"],
                                   on_change: proc do |val|
                                     info "Intensity Controller ##{idx} => #{val}"
                                     ival = int_vals[val]
                                     NODES["SHIFTED_#{idx}"]
                                       .set_range(ival[0], ival[1])
                                   end)
  NODES["SHIFTED_#{idx}"] = last
end

SAT_STATES  = []
sat_cfg     = CONFIG["simulation"]["controls"]["saturation"]
sat_colors  = sat_cfg["colors"]
sat_widget  = Kernel.const_get(sat_cfg["widget"])
sat_cfg["positions"].each do |(xx, yy)|
  SAT_STATES << sat_widget.new(launchpad: INTERACTION,
                               x:         xx,
                               y:         yy,
                               size:      sat_cfg["size"],
                               on:        sat_colors["on"],
                               off:       sat_colors["off"],
                               down:      sat_colors["down"])
end

last = NODES["SPOTLIT"] = Node::Transform::Spotlight.new(source: last)
FINAL_RESULT            = last # The end node that will be rendered to the lights.
sl_cfg                  = CONFIG["simulation"]["controls"]["spotlighting"]
sl_colors               = sl_cfg["colors"]
sl_map_raw              = sl_cfg["mappings"]
sl_pos                  = sl_map_raw.flatten
SL_STATE                = Widgets::RadioGroup.new(launchpad:   INTERACTION,
                                                  x:           sl_cfg["x"],
                                                  y:           sl_cfg["y"],
                                                  size:        [sl_map_raw.map(&:length).sort[-1],
                                                                sl_map_raw.length],
                                                  on:          sl_colors["on"],
                                                  off:         sl_colors["off"],
                                                  down:        sl_colors["down"],
                                                  on_select:   proc do |x|
                                                    info "Spotlighting ##{x}"
                                                    NODES["SPOTLIT"].spotlight(sl_pos[x])
                                                  end,
                                                  on_deselect: proc do
                                                    info "Spotlighting Disabled"
                                                    NODES["SPOTLIT"].clear!
                                                  end)

NODES.each do |name, node|
  node.debug = DEBUG_FLAGS[name]
end

###############################################################################
# Operational Configuration
###############################################################################
ITERATIONS                = env_int("ITERATIONS", true) || 0
TIME_TO_DIE               = [false]
Thread.abort_on_exception = false

###############################################################################
# Profiling Support
###############################################################################
e_cfg = CONFIG["simulation"]["controls"]["exit"]
EXIT_BUTTON = Widgets::Button.new(launchpad: INTERACTION,
                                  position:  e_cfg["position"],
                                  color:     e_cfg["colors"]["color"],
                                  down:      e_cfg["colors"]["down"],
                                  on_press:  lambda do |value|
                                    return unless value != 0
                                    important "Ending simulation."
                                    TIME_TO_DIE[0] = true
                                  end)

def start_ruby_prof!
  return unless PROFILE_RUN == "ruby-prof"
  important "Enabling ruby-prof, be careful!"
  require "ruby-prof"
  RubyProf.measure_mode = RubyProf::ALLOCATIONS
  RubyProf.start
end

def stop_ruby_prof!
  return unless PROFILE_RUN == "ruby-prof"
  result  = RubyProf.stop
  printer = RubyProf::CallStackPrinter.new(result)
  File.open("results.html", "w") do |fh|
    printer.print(fh)
  end
end

###############################################################################
# Main Simulation
###############################################################################
def announce_iteration_config(iters)
  if iters > 0
    debug "Running for #{iters} iterations."
  else
    debug "Running until we're killed.  Send SIGHUP to terminate with stats."
  end
end

def clear_board!
  INT_STATES.map(&:blank)
  sleep 0.01 # 88 updates/sec input limit!
  SAT_STATES.map(&:blank)
  sleep 0.01 # 88 updates/sec input limit!
  SL_STATE.blank
  EXIT_BUTTON.blank
end

def main
  announce_iteration_config(ITERATIONS)

  global_results = Results.new

  input_thread = Thread.new do
    guard_call("Input Handler Setup") do
      Thread.stop
      # TODO: This isn't setting the actual light state properly.  AUGH!  It
      # TODO: *does* set the LED and the controller state which is handy, but
      # TODO: still...
      INT_STATES.each { |ctrl| ctrl.update(0) }
      SAT_STATES.each { |ctrl| ctrl.update(3) }
      SL_STATE.update(nil)
      EXIT_BUTTON.update(false)

      # ... and of course we don't want to sleep on this loop, or `join` the
      # thread for the same reason.
      INTERACTION.start
    end
  end

  if USE_SIM
    sim_thread = Thread.new do
      guard_call("Base Simulation") do
        Thread.stop

        loop do
          t = Time.now.to_f
          FINAL_RESULT.update(t)
          elapsed = Time.now.to_f - t
          # Try to adhere to a specific update frequency...
          sleep FRAME_PERIOD - elapsed if elapsed < FRAME_PERIOD
        end
      end
    end
  end

  if USE_SWEEP
    # TODO: Make this terminate after main simulation threads have all stopped.
    sweep_thread = Thread.new do
      max_hue     = CONFIG["simulation"]["sweep"]["max"]
      min_hue     = CONFIG["simulation"]["sweep"]["min"]
      sweep_len   = CONFIG["simulation"]["sweep"]["length"]

      results     = Results.new
      hue_target  = max_hue
      guard_call("Sweeper") do
        Thread.stop

        loop do
          before_time = Time.now.to_f
          # TODO: Hoist this into a sawtooth simulation function.
          hue_target  = (hue_target == max_hue) ? min_hue : max_hue
          data        = with_transition_time({ "hue" => hue_target }, sweep_len)
          # TODO: Hoist the hash into something reusable above...
          requests    = CONFIG["bridges"]
                        .map do |(_name, config)|
                          { method:   :put,
                            url:      hue_group_endpoint(config, 0),
                            put_data: Oj.dump(data) }.merge(EASY_OPTIONS)
                        end

          Curl::Multi.http(requests, MULTI_OPTIONS) do # |easy|
            # Apparently performed for each request?  Or when idle?  Or...

            # dns_cache_timeout head header_size header_str headers
            # http_connect_code last_effective_url last_result low_speed_limit
            # low_speed_time num_connects on_header os_errno redirect_count
            # request_size

            # app_connect_time connect_time name_lookup_time pre_transfer_time
            # start_transfer_time total_time

            # Bytes/sec, I think:
            # download_speed upload_speed

            # The following are all Float, and downloaded_content_length can be
            # -1.0 when a transfer times out(?).
            # downloaded_bytes downloaded_content_length uploaded_bytes
            # uploaded_content_length
          end

          global_results.add_from(results)
          results.clear!

          sleep 0.05 while (Time.now.to_f - before_time) <= sweep_len
        end
      end
    end
  end

  if USE_LIGHTS
    transition  = CONFIG["simulation"]["transition"]
    threads     = LIGHTS_FOR_THREADS.map do |(bridge_name, (lights, _mask))|
      Thread.new do
        guard_call(bridge_name) do
          config    = CONFIG["bridges"][bridge_name]
          results   = Results.new
          iterator  = (ITERATIONS > 0) ? ITERATIONS.times : loop

          debug bridge_name, "Thread set to handle #{lights.count} lights"\
            " (#{lights.map(&:first).join(', ')})."

          Thread.stop
          sleep SPREAD_SLEEP unless SPREAD_SLEEP == 0

          requests = lights
                     .map do |(idx, lid)|
                       LazyRequestConfig.new(config, hue_light_endpoint(config, lid), results) do
                         data = { "bri" => (FINAL_RESULT[idx] * 254).to_i }
                         with_transition_time(data, transition)
                       end
                     end

          iterator.each do
            Curl::Multi.http(requests.dup, MULTI_OPTIONS) do
            end

            global_results.add_from(results)
            results.clear!

            sleep(BETWEEN_SLEEP) unless BETWEEN_SLEEP == 0
            break if TIME_TO_DIE[0]
          end
        end
      end
    end
  else
    threads = []
  end

  # Wait for threads to finish initializing...
  sleep 0.01 while threads.find { |thread| thread.status != "sleep" } if USE_LIGHTS
  sleep 0.01 while sweep_thread.status != "sleep" if USE_SWEEP
  sleep 0.01 while sim_thread.status != "sleep" if USE_SIM
  sleep 0.01 while input_thread.status != "sleep"
  if SKIP_GC
    important "Disabling garbage collection!  BE CAREFUL!"
    GC.disable
  end
  debug "Threads are ready to go, waking them up."
  global_results.begin!
  start_ruby_prof!
  sim_thread.run if USE_SIM
  sweep_thread.run if USE_SWEEP
  threads.each(&:run) if USE_LIGHTS
  input_thread.run

  trap("EXIT") do
    guard_call("Exit Handler") do
      global_results.done!
      print_results(global_results)
      clear_board!

      stop_ruby_prof!
      index = 0
      NODES.each do |name, node|
        next unless DEBUG_FLAGS[name]
        node.snapshot_to!("%02d_%s.png" % [index, name.downcase])
        index += 1
      end
      if DEBUG_FLAGS["OUTPUT"]
        File.open("output.raw", "w") do |fh|
          fh.write(LazyRequestConfig::GLOBAL_HISTORY.join("\n"))
          fh.write("\n")
        end
      end
    end
  end

  if USE_LIGHTS
    threads.each(&:join)
  else
    loop do
      break if TIME_TO_DIE[0]
      sleep 0.1
    end
  end
  input_thread.terminate
  sweep_thread.terminate if USE_SWEEP
  sim_thread.terminate if USE_SIM
  sleep 0.1
end

###############################################################################
# Launcher
###############################################################################
if PROFILE_RUN == "memory_profiler"
  important "Enabling memory_profiler, be careful!"
  require "memory_profiler"
  report = MemoryProfiler.report do
    main
    important "Preparing MemoryProfiler report..."
  end
  important "Dumping MemoryProfiler report..."
  report.pretty_print
else
  main
end

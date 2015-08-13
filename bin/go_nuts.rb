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
require_relative "./lib/vector2"

require_relative "./lib/node/base"
require_relative "./lib/node/simulation/base"
require_relative "./lib/node/transform/base"

require_relative "./lib/node/simulation/const"
require_relative "./lib/node/simulation/perlin"
require_relative "./lib/node/simulation/wave2"

require_relative "./lib/node/transform/contrast"
require_relative "./lib/node/transform/range"
require_relative "./lib/node/transform/spotlight"

require_relative "./lib/widget/base"
require_relative "./lib/widget/vertical_slider"
require_relative "./lib/widget/radio_group"
require_relative "./lib/widget/toggle"
require_relative "./lib/widget/button"

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

###############################################################################
# Timing Configuration
#
# Play with this to see how error rates are affected.
###############################################################################
# TODO: Instead of a between sleep, we should look at how many ms we ought to
# TODO: wait after an update to avoid flooding the network.  That'll depend on
# TODO: number of components updated, etc.
SPREAD_SLEEP    = env_float("SPREAD_SLEEP") || 0.0
BETWEEN_SLEEP   = env_float("BETWEEN_SLEEP") || 0.0

###############################################################################
# Effect Configuration
#
# Tweak this to change the visual effect(s).
###############################################################################
# TODO: Move all of these into the config...
SWEEP_LENGTH    = 2.0

TRANSITION      = env_float("TRANSITION") || 0.4 # In seconds, 1/10th sec. prec!

# Ballpark estimation of Jen's palette:
MIN_HUE         = env_int("MIN_HUE", true) || 48_000
MAX_HUE         = env_int("MAX_HUE", true) || 51_000

# Intensity ranges:
INT_VALUES  = [ [0.00, 0.00],
                [0.00, 0.10],
                [0.05, 0.20],
                [0.15, 0.35],
                [0.30, 0.60],
                [0.50, 1.00] ]

INT_ON          = { r: 0x27,          b: 0x3F }
INT_OFF         = { r: 0x02,          b: 0x04 }
INT_DOWN        = { r: 0x27, g: 0x10, b: 0x3F }

SL_ON           = { r: 0x27, g: 0x00, b: 0x00 }
SL_OFF          = { r: 0x02, g: 0x00, b: 0x00 }
SL_DOWN         = { r: 0x3F, g: 0x10, b: 0x10 }

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
       NODES["CONST"]      = Node::Simulation::Const.new(lights: num_lights)
       NODES["WAVE2"]      = Node::Simulation::Wave2.new(lights: num_lights, speed: WAVE2_SPEED)
last = NODES["PERLIN"]     = Node::Simulation::Perlin.new(lights: num_lights, speed: PERLIN_SPEED)

# Transform nodes (act as a chain of modifiers):
# TODO: Parameterize a few more things like function/iterations below.
last = NODES["STRETCHED"]  = Node::Transform::Contrast.new(function:   Perlin::Curve::CUBIC, # LINEAR, CUBIC, QUINTIC -- don't bother using iterations>1 with LINEAR!
                                                           iterations: 3,
                                                           source:     last)
# Create one control group here per "quadrant"...
t_index = 0
LIGHTS_FOR_THREADS.each do |(_bridge_name, (lights, mask))|
  mask = [false] * num_lights
  lights.map(&:first).each { |idx| mask[idx] = true }

  last                = Node::Transform::Range.new(initial_min: INT_VALUES[0][0],
                                                   initial_max: INT_VALUES[0][1],
                                                   source:      last,
                                                   mask:        mask)
  INT_STATES[t_index] = Widget::VerticalSlider.new(launchpad: INTERACTION,
                                                   x:         t_index,
                                                   y:         2,
                                                   height:    6,
                                                   on:        INT_ON,
                                                   off:       INT_OFF,
                                                   down:      INT_DOWN)
  NODES["SHIFTED_#{t_index}"]  = last
  t_index                     += 1
end

last = NODES["SPOTLIT"] = Node::Transform::Spotlight.new(source: last)
sl_positions_raw        = CONFIG["spotlight_positions"].map { |row| row.map { |i| i.to_i }}
sl_width                = sl_positions_raw.map { |row| row.length }.sort.last
sl_height               = sl_positions_raw.length
SL_POSITIONS            = sl_positions_raw.flatten
SL_STATE                = Widget::RadioGroup.new(launchpad:   INTERACTION,
                                                 x:           0,
                                                 y:           0,
                                                 height:      sl_height,
                                                 width:       sl_width,
                                                 on:          SL_ON,
                                                 off:         SL_OFF,
                                                 down:        SL_DOWN,
                                                 on_select:   proc do |x|
                                                   info "Spotlighting ##{x}"
                                                   NODES["SPOTLIT"].spotlight(SL_POSITIONS[x])
                                                 end,
                                                 on_deselect: proc do
                                                   info "Spotlighting Disabled"
                                                   NODES["SPOTLIT"].clear!
                                                 end)

# The end node that will be rendered to the lights:
FINAL_RESULT            = last

NODES.each do |name, node|
  node.debug = DEBUG_FLAGS[name]
end

###############################################################################
# Operational Configuration
###############################################################################
ITERATIONS = env_int("ITERATIONS", true) || 0
TIME_TO_DIE = [false]

###############################################################################
# Profiling Support
###############################################################################
EXIT_BUTTON = Widget::Button.new(launchpad: INTERACTION,
                                 position:  :mixer,
                                 color:     Widget::Base::DARK_GRAY,
                                 down:      Widget::Base::WHITE,
                                 on_press:  proc do |value|
                                   if value != 0
                                     important "Goodnight, Gracie!"
                                     TIME_TO_DIE[0] = true
                                   end
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
def main
  if ITERATIONS > 0
    debug "Running for #{ITERATIONS} iterations."
  else
    debug "Running until we're killed.  Send SIGHUP to terminate with stats."
  end

  global_results = Results.new

  Thread.abort_on_exception = false

  # Brightness range controls:
  INT_STATES.each_with_index do |ctrl, idx|
    ctrl.on_change = proc do |val|
      info "Intensity Controller ##{idx} => #{val}"
      NODES["SHIFTED_#{idx}"].set_range(INT_VALUES[val][0], INT_VALUES[val][1])
    end
  end

  input_thread = Thread.new do
    guard_call("Input Handler Setup") do
      Thread.stop
      # TODO: This isn't setting the actual light state properly.  AUGH!  It
      # TODO: *does* set the LED and the controller state which is handy, but
      # TODO: still...
      INT_STATES.each { |ctrl| ctrl.update(0) }
      SL_STATE.update(nil)
      EXIT_BUTTON.update(false)

      # ... and of course we don't want to sleep on this loop, or `join` the
      # thread for the same reason.
      INTERACTION.start
    end
  end

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

  if USE_SWEEP
    # TODO: Make this terminate after main simulation threads have all stopped.
    sweep_thread = Thread.new do
      hue_target  = MAX_HUE
      results     = Results.new

      guard_call("Sweeper") do
        Thread.stop

        loop do
          before_time = Time.now.to_f
          # TODO: Hoist this into a sawtooth simulation function.
          hue_target  = (hue_target == MAX_HUE) ? MIN_HUE : MAX_HUE
          data        = with_transition_time({ "hue" => hue_target }, SWEEP_LENGTH)
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

          sleep 0.05 while (Time.now.to_f - before_time) <= SWEEP_LENGTH
        end
      end
    end
  end

  if USE_LIGHTS
    threads = LIGHTS_FOR_THREADS.map do |(bridge_name, (lights, _mask))|
      Thread.new do
        guard_call(bridge_name) do
          config    = CONFIG["bridges"][bridge_name]
          results   = Results.new
          iterator  = (ITERATIONS > 0) ? ITERATIONS.times : loop

          debug bridge_name, "Thread set to handle #{lights.count} lights (#{lights.map(&:first).join(", ")})."

          Thread.stop
          sleep SPREAD_SLEEP unless SPREAD_SLEEP == 0

          requests  = lights
                      .map do |(idx, lid)|
                        LazyRequestConfig.new(config, hue_light_endpoint(config, lid), results) do
                          data = { "bri" => (FINAL_RESULT[idx] * 254).to_i }
                          with_transition_time(data, TRANSITION)
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
  sleep 0.01 while sim_thread.status != "sleep"
  sleep 0.01 while input_thread.status != "sleep"
  if SKIP_GC
    important "Disabling garbage collection!  BE CAREFUL!"
    GC.disable
  end
  debug "Threads are ready to go, waking them up."
  global_results.begin!
  start_ruby_prof!
  sim_thread.run
  sweep_thread.run if USE_SWEEP
  threads.each(&:run) if USE_LIGHTS
  input_thread.run

  trap("EXIT") do
    guard_call("Exit Handler") do
      global_results.done!
      print_results(global_results)
      INT_STATES.map(&:blank)
      SL_STATE.blank
      EXIT_BUTTON.blank

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
  sim_thread.terminate
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

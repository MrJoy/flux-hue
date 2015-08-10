#!/usr/bin/env ruby
# https://github.com/taf2/curb/tree/master/bench

# TODO: Play with fibers using the more involved `Curl::Multi` interface that
# TODO: gives us an idle callback.
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

require_relative "./lib/output"
require_relative "./lib/config"
require_relative "./lib/logging"
require_relative "./lib/env"
require_relative "./lib/utility"
require_relative "./lib/results"
require_relative "./lib/http"
require_relative "./lib/vector2"
require_relative "./lib/node"
require_relative "./lib/root_node"
require_relative "./lib/transform_node"
require_relative "./lib/perlin_simulation"
require_relative "./lib/contrast_transform"
require_relative "./lib/range_transform"

###############################################################################
# Profiling
###############################################################################
PROFILE_RUN = env_int("PROFILE_RUN", true) != 0
if PROFILE_RUN
  require "ruby-prof"
  RubyProf.measure_mode = RubyProf::ALLOCATIONS
  RubyProf.start
end
DEBUG_PERLIN    = env_int("DEBUG_PERLIN", true) != 0
DEBUG_CONTRAST  = env_int("DEBUG_CONTRAST", true) != 0
DEBUG_RANGE     = env_int("DEBUG_RANGE", true) != 0

###############################################################################
# Timing Configuration
#
# Play with this to see how error rates are affected.
###############################################################################
ITERATIONS      = env_int("ITERATIONS", true) || 0

SPREAD_SLEEP    = env_float("SPREAD_SLEEP") || 0.0
BETWEEN_SLEEP   = env_float("BETWEEN_SLEEP") || 0.0

VERBOSE         = env_int("VERBOSE")

###############################################################################
# Effect
#
# Tweak this to change the visual effect.
###############################################################################
# TODO: Move all of these into the config...
USE_SWEEP       = (env_int("USE_SWEEP", true) || 1) != 0
SWEEP_LENGTH    = 2.0

TRANSITION      = env_float("TRANSITION") || 0.4 # In seconds, 1/10th sec. prec!

# Ballpark estimation of Jen's palette:
MIN_HUE         = env_int("MIN_HUE", true) || 48_000
MAX_HUE         = env_int("MAX_HUE", true) || 51_000
MIN_BRI         = env_float("MIN_BRI") || 0.25
MAX_BRI         = env_float("MAX_BRI") || 0.75

PERLIN_SCALE_Y  = env_float("PERLIN_SCALE_Y") || 4.0

# TODO: Do we need to modulate this?  Also, we should dump our seed with the
# TODO: state above as well.
BASE_SIMULATION = PerlinSimulation.new(lights:    CONFIG["main_lights"].length,
                                       seed:      0,
                                       speed:     Vector2.new(x: 0.1, y: PERLIN_SCALE_Y),
                                       debug:     DEBUG_PERLIN)
CONTRASTED      = ContrastTransform.new(lights:     CONFIG["main_lights"].length,
                                        function:   Perlin::Curve::CUBIC, # LINEAR, CUBIC, QUINTIC -- don't bother using iterations>1 with LINEAR!
                                        iterations: 3,
                                        source:     BASE_SIMULATION,
                                        debug:      DEBUG_CONTRAST)
RANGED          = RangeTransform.new(lights: CONFIG["main_lights"].length,
                                     initial_min: MIN_BRI,
                                     initial_max: MAX_BRI,
                                     source:      CONTRASTED,
                                     debug:       DEBUG_RANGE)
def perlin(x, _s, min, max)
  (RANGED[x] * 254).to_i
end

def wave2(x, s, min, max)
  elapsed = Time.now.to_f
  # TODO: Downscale x?
  (((Math.sin((elapsed + x) * s) + 1) * 0.5 * (max - min)) + min).to_i
end

def wave(_x, s, min, max)
  elapsed = Time.now.to_f
  (((Math.sin(elapsed * s) + 1) * 0.5 * (max - min)) + min).to_i
end

###############################################################################
# Other Configuration
###############################################################################
SKIP_GC           = !!env_int("SKIP_GC")

###############################################################################
# Main
###############################################################################

if ITERATIONS > 0
  debug "Running for #{ITERATIONS} iterations."
else
  debug "Running until we're killed.  Send SIGHUP to terminate with stats."
end

lights_for_threads  = in_groups(CONFIG["main_lights"])
global_results      = Results.new

Thread.abort_on_exception = false

base_sim_thread = Thread.new do
  guard_call("Base Simulation") do
    Thread.stop

    loop do
      t = Time.now.to_f
      RANGED.update(t)
      elapsed = Time.now.to_f - t
      # Try to adhere to a 10ms update frequency...
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

threads = lights_for_threads.map do |(bridge_name, lights)|
  Thread.new do
    guard_call(bridge_name) do
      config    = CONFIG["bridges"][bridge_name]
      results   = Results.new
      iterator  = (ITERATIONS > 0) ? ITERATIONS.times : loop

      debug bridge_name, "Thread set to handle #{lights.count} lights."

      Thread.stop
      sleep SPREAD_SLEEP unless SPREAD_SLEEP == 0

      requests  = lights
                  .map do |(idx, lid)|
                    LazyRequestConfig.new(config, hue_light_endpoint(config, lid), results) do
                      data = { "bri" => (RANGED[idx] * 254).to_i }
                      with_transition_time(data, TRANSITION)
                    end
                  end

      iterator.each do
        Curl::Multi.http(requests.dup, MULTI_OPTIONS) do
        end

        global_results.add_from(results)
        results.clear!

        sleep(BETWEEN_SLEEP) unless BETWEEN_SLEEP == 0
      end
    end
  end
end

# Wait for threads to finish initializing...
sleep 0.01 while threads.find { |thread| thread.status != "sleep" }
sleep 0.01 while sweep_thread.status != "sleep" if USE_SWEEP
sleep 0.01 while base_sim_thread.status != "sleep"
if SKIP_GC
  important "Disabling garbage collection!  BE CAREFUL!"
  GC.disable
end
debug "Threads are ready to go, waking them up."
global_results.begin!
base_sim_thread.run
sweep_thread.run if USE_SWEEP
threads.each(&:run)

trap("EXIT") do
  guard_call("Exit Handler") do
    global_results.done!
    print_results(global_results)
    if PROFILE_RUN
      result  = RubyProf.stop
      printer = RubyProf::CallStackPrinter.new(result)
      File.open("results.html", "w") do |fh|
        printer.print(fh)
      end
    end
    BASE_SIMULATION.snapshot_to!("00_perlin.png") if DEBUG_PERLIN
    CONTRASTED.snapshot_to!("01_contrasted.png") if DEBUG_CONTRAST
    RANGED.snapshot_to!("02_ranged.png") if DEBUG_RANGE
  end
end

threads.each(&:join)
sweep_thread.terminate if USE_SWEEP
base_sim_thread.terminate

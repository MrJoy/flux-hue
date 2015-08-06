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

require_relative "./lib/config"
require_relative "./lib/logging"
require_relative "./lib/env"
require_relative "./lib/utility"
require_relative "./lib/results"
require_relative "./lib/http"

###############################################################################
# Profiling
###############################################################################
PROFILE_RUN = env_int("PROFILE_RUN") != 0
if PROFILE_RUN
  require "ruby-prof"
  RubyProf.measure_mode = RubyProf::ALLOCATIONS
  RubyProf.start
end

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
USE_SWEEP     = (env_int("USE_SWEEP", true) || 1) != 0
TRANSITION    = env_float("TRANSITION") || 0.4 # In seconds, 1/10th sec. prec!
SWEEP_LENGTH  = 2.0

# Ballpark estimation of Jen's palette:
MIN_HUE       = env_int("MIN_HUE", true) || 48_000
MAX_HUE       = env_int("MAX_HUE", true) || 51_000
MIN_SAT       = env_int("MIN_SAT", true) || 212
MAX_SAT       = env_int("MAX_SAT", true) || 254
MIN_BRI       = env_int("MIN_BRI", true) || 63
MAX_BRI       = env_int("MAX_BRI", true) || 191

TIMESCALE_H   = env_float("TIMESCALE_H") || 0.2
TIMESCALE_S   = env_float("TIMESCALE_S") || 1.0
TIMESCALE_B   = env_float("TIMESCALE_B") || 2.0

HUE_FUNC      = ENV.key?("HUE_FUNC") ? ENV["HUE_FUNC"] : "none"
SAT_FUNC      = ENV.key?("SAT_FUNC") ? ENV["SAT_FUNC"] : "none"
BRI_FUNC      = ENV.key?("BRI_FUNC") ? ENV["BRI_FUNC"] : "perlin"

# TODO: Build out a variety of noise configurations.  Parameterize them, and
# TODO: allow meta-parameterization as well.
PERSISTENCE   = 1
OCTAVES       = 1
# TODO: Dump [BASIS_TIME, Time.now.to_f] on termination and read on start to
# TODO: allow resuming at correct time offset.
BASIS_TIME    = Time.now.to_f # Large Y values frighten and confuse our
                              # Perlin generator...
# TODO: Do we need to modulate this?  Also, we should dump our seed with the
# TODO: state above as well.
SEED          = BASIS_TIME.to_i % 1000 # Large seeds frighten and confuse our
                                       # Perlin generator...
PERLIN        = Perlin::Noise.new(2)
CONTRAST      = Perlin::Curve.contrast(Perlin::Curve::CUBIC, 3)

def perlin(x, s, min, max)
  # Ugly hack because the Perlin lib we're using doesn't like extreme Y values,
  # apparently.  It starts spitting zeroes back at us.
  elapsed = Time.now.to_f - BASIS_TIME
  raw     = CONTRAST.call(PERLIN[x, elapsed * s])
  ((raw * (max - min)) + min).to_i
end

def wave2(x, s, min, max)
  elapsed = Time.now.to_f - BASIS_TIME
  # TODO: Downscale x?
  (((Math.sin((elapsed + x) * s) + 1) * 0.5 * (max - min)) + min).to_i
end

def wave(_x, s, min, max)
  elapsed = Time.now.to_f - BASIS_TIME
  (((Math.sin(elapsed * s) + 1) * 0.5 * (max - min)) + min).to_i
end

HUE_GEN = {
  "perlin"  => proc { |idx| perlin(idx, TIMESCALE_H, MIN_HUE, MAX_HUE) },
  "wave"    => proc { |idx| wave(idx, TIMESCALE_H, MIN_HUE, MAX_HUE) },
  "wave2"   => proc { |idx| wave2(idx, TIMESCALE_H, MIN_HUE, MAX_HUE) },
}

SAT_GEN = {
  "perlin"  => proc { |idx| perlin(idx, TIMESCALE_S, MIN_SAT, MAX_SAT) },
  "wave"    => proc { |idx| wave(idx, TIMESCALE_S, MIN_SAT, MAX_SAT) },
  "wave2"   => proc { |idx| wave2(idx, TIMESCALE_S, MIN_SAT, MAX_SAT) },
}

BRI_GEN = {
  "perlin"  => proc { |idx| perlin(idx, TIMESCALE_B, MIN_BRI, MAX_BRI) },
  "wave"    => proc { |idx| wave(idx, TIMESCALE_B, MIN_BRI, MAX_BRI) },
  "wave2"   => proc { |idx| wave2(idx, TIMESCALE_B, MIN_BRI, MAX_BRI) },
}

###############################################################################
# Other Configuration
###############################################################################
SKIP_GC           = !!env_int("SKIP_GC")

###############################################################################
# Helper Functions
###############################################################################
def validate_func_for!(component, value, functions)
  return if functions.key?(value)
  return if value == "none"
  error "Unknown value for #{component.upcase}_FUNC: `#{value}`!"
end

###############################################################################
# Main
###############################################################################
validate_func_for!("hue", HUE_FUNC, HUE_GEN)
validate_func_for!("sat", SAT_FUNC, SAT_GEN)
validate_func_for!("bri", BRI_FUNC, BRI_GEN)

if ITERATIONS > 0
  debug "Running for #{ITERATIONS} iterations."
else
  debug "Running until we're killed.  Send SIGHUP to terminate with stats."
end

lights_for_threads  = in_groups(CONFIG["main_lights"])
global_results      = Results.new

Thread.abort_on_exception = false
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

      iterator.each do
        requests  = lights
                    .map do |(idx, lid)|
                      LazyRequestConfig.new(config, hue_light_endpoint(config, lid), results) do
                        data = {}
                        data["hue"] = HUE_GEN[HUE_FUNC].call(idx) if HUE_GEN[HUE_FUNC]
                        data["sat"] = SAT_GEN[SAT_FUNC].call(idx) if SAT_GEN[SAT_FUNC]
                        data["bri"] = BRI_GEN[BRI_FUNC].call(idx) if BRI_GEN[BRI_FUNC]
                        # data["bri"] = wave2(idx, TIMESCALE_B, MIN_BRI, MAX_BRI)
                        with_transition_time(data, TRANSITION)
                      end
                    end

        Curl::Multi.http(requests, MULTI_OPTIONS) do
        end

        global_results.add_from(results)
        results.clear!

        sleep(BETWEEN_SLEEP) unless BETWEEN_SLEEP == 0
      end
    end
  end
end

def format_float(num); num ? num.round(2) : "-"; end

def format_rate(rate); "#{format_float(rate)}/sec"; end

def print_stat(name, value, rate)
  important "* #{value} #{name} (#{format_rate(rate)})"
end

STATS = [
  ["requests",       :requests,      :requests_sec],
  ["successes",      :successes,     :successes_sec],
  ["failures",       :failures,      :failures_sec],
  ["hard timeouts",  :hard_timeouts, :hard_timeouts_sec],
  ["soft timeouts",  :soft_timeouts, :soft_timeouts_sec],
]

def print_stats(results)
  STATS.each do |(name, count, rate)|
    print_stat(name, results.send(count), results.send(rate))
  end
end

# TODO: Show per-bridge and aggregate stats.
def print_results(results)
  important ""
  print_stats(results)

  important "* #{format_float(results.failure_rate)}% failure rate"
  suffix  = " (#{format_float(results.elapsed / ITERATIONS.to_f)}/iteration)" if ITERATIONS > 0
  important "* #{format_float(results.elapsed)} seconds elapsed#{suffix}"
end

# Wait for threads to finish initializing...
sleep 0.01 while threads.find { |thread| thread.status != "sleep" }
sleep 0.01 while sweep_thread.status != "sleep" if USE_SWEEP
if SKIP_GC
  important "Disabling garbage collection!  BE CAREFUL!"
  GC.disable
end
debug "Threads are ready to go, waking them up."
global_results.begin!
sweep_thread.run if USE_SWEEP
threads.each(&:run)

trap("EXIT") do
  if PROFILE_RUN
    result  = RubyProf.stop
    printer = RubyProf::CallStackPrinter.new(result)
    File.open("results.html", "w") do |fh|
      printer.print(fh)
    end
  end
  global_results.done!
  print_results(global_results)
end

threads.each(&:join)
sweep_thread.terminate if USE_SWEEP

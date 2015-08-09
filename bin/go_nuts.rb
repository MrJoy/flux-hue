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

require_relative "./lib/output"
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
  elapsed = Time.now.to_f
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

# A 2-component vector, where components go from 0.0..1.0.
class Vector2
  attr_reader :x, :y
  def initialize(x: 0.0, y: 0.0)
    @x = x
    @y = y
  end
end

# Generalized representation for the state of an ordered set of lights.
class State
  attr_accessor :history

  def initialize(lights:, initial_state: nil, debug: false)
    @debug    = debug
    @history  = [] if @debug
    @lights   = lights
    @state    = Array.new(@lights)
    lights.times do |n|
      @state[n] = initial_state ? initial_state[n] : 0.0
    end
  end

  def [](n); @state[n]; end
  def []=(n, val); @state[n] = val; end

  def update(t)
    @history << { t: t, state: @state.dup } if @debug
  end
end

# Manage and run a Perlin-noise based simulation.
class PerlinSimulation < State
  def initialize(lights:, initial_state: nil, seed:, speed:, debug: false)
    super(lights: lights, initial_state: initial_state, debug: debug)
    @speed      = speed
    # TODO: If we just cheat and use a fixed seed, that should be totally fine
    # TODO: and make resumability much simpler.
    #
    # TODO: Perlin::Noise also supports interval and curve options...
    @perlin     = Perlin::Noise.new(2, seed: seed)
    @contrast   = Perlin::Curve.contrast(Perlin::Curve::CUBIC, 3)
  end

  def update(t)
    @lights.times do |n|
      self[n] = @contrast.call(@perlin[n * @speed.x, t * @speed.y])
    end
    super(t)
  end
end

require "oily_png"
lights  = 28
perlin  = PerlinSimulation.new(lights: lights,
                               seed:   0,
                               speed:  Vector2.new(x: 0.1, y: 4.0),
                               debug:  true)
prev = t = Time.now.to_f
100.times do |n|
  t = Time.now.to_f
  perlin.update(t)
  elapsed = Time.now.to_f - t
  sleep 0.01 - elapsed if elapsed < 0.01
end

prev    = perlin.history.first[:t]
history = perlin
          .history
          .map do |snapshot|
            t            = snapshot[:t]
            elapsed      = ((t - prev) * 100).round.to_i * 1
            prev         = t
            snapshot[:y] = (elapsed > 0) ? elapsed : 1
            snapshot
          end
width   = 2
size_x  = lights * width
size_y  = history.map { |sn| sn[:y] }.inject(0) { |x, y| x + y }

puts "Total Height: #{size_y}, Total Width: #{size_x}"
png = ChunkyPNG::Image.new(size_x, size_y, ChunkyPNG::Color::TRANSPARENT)
y   = 0
history.each do |snapshot|
  colors  = snapshot[:state]
            .map { |z| (z * 254).to_i }
            .map { |z| ChunkyPNG::Color.rgba(z, z, z, 255) }
  (y..(y + snapshot[:y] - 1)).each do |yy|
    colors.each_with_index do |c, x|
      x1 = x * width
      x2 = (x + 1) * width - 1
      (x1..x2).each do |xx|
        png[xx, yy] = c
      end
    end
  end
  y += snapshot[:y]
end
png.save("perlin.png", interlace: false)

# validate_func_for!("hue", HUE_FUNC, HUE_GEN)
# validate_func_for!("sat", SAT_FUNC, SAT_GEN)
# validate_func_for!("bri", BRI_FUNC, BRI_GEN)

# if ITERATIONS > 0
#   debug "Running for #{ITERATIONS} iterations."
# else
#   debug "Running until we're killed.  Send SIGHUP to terminate with stats."
# end

# lights_for_threads  = in_groups(CONFIG["main_lights"])
# global_results      = Results.new

# Thread.abort_on_exception = false
# if USE_SWEEP
#   # TODO: Make this terminate after main simulation threads have all stopped.
#   sweep_thread = Thread.new do
#     hue_target  = MAX_HUE
#     results     = Results.new

#     guard_call("Sweeper") do
#       Thread.stop

#       loop do
#         before_time = Time.now.to_f
#         # TODO: Hoist this into a sawtooth simulation function.
#         hue_target  = (hue_target == MAX_HUE) ? MIN_HUE : MAX_HUE
#         data        = with_transition_time({ "hue" => hue_target }, SWEEP_LENGTH)
#         requests    = CONFIG["bridges"]
#                       .map do |(_name, config)|
#                         { method:   :put,
#                           url:      hue_group_endpoint(config, 0),
#                           put_data: Oj.dump(data) }.merge(EASY_OPTIONS)
#                       end

#         Curl::Multi.http(requests, MULTI_OPTIONS) do # |easy|
#           # Apparently performed for each request?  Or when idle?  Or...

#           # dns_cache_timeout head header_size header_str headers
#           # http_connect_code last_effective_url last_result low_speed_limit
#           # low_speed_time num_connects on_header os_errno redirect_count
#           # request_size

#           # app_connect_time connect_time name_lookup_time pre_transfer_time
#           # start_transfer_time total_time

#           # Bytes/sec, I think:
#           # download_speed upload_speed

#           # The following are all Float, and downloaded_content_length can be
#           # -1.0 when a transfer times out(?).
#           # downloaded_bytes downloaded_content_length uploaded_bytes
#           # uploaded_content_length
#         end

#         global_results.add_from(results)
#         results.clear!

#         sleep 0.05 while (Time.now.to_f - before_time) <= SWEEP_LENGTH
#       end
#     end
#   end
# end

# threads = lights_for_threads.map do |(bridge_name, lights)|
#   Thread.new do
#     guard_call(bridge_name) do
#       config    = CONFIG["bridges"][bridge_name]
#       results   = Results.new
#       iterator  = (ITERATIONS > 0) ? ITERATIONS.times : loop

#       debug bridge_name, "Thread set to handle #{lights.count} lights."

#       Thread.stop
#       sleep SPREAD_SLEEP unless SPREAD_SLEEP == 0

#       requests  = lights
#                   .map do |(idx, lid)|
#                     LazyRequestConfig.new(config, hue_light_endpoint(config, lid), results) do
#                       data = {}
#                       data["hue"] = HUE_GEN[HUE_FUNC].call(idx) if HUE_GEN[HUE_FUNC]
#                       data["sat"] = SAT_GEN[SAT_FUNC].call(idx) if SAT_GEN[SAT_FUNC]
#                       data["bri"] = BRI_GEN[BRI_FUNC].call(idx) if BRI_GEN[BRI_FUNC]
#                       # data["bri"] = wave2(idx, TIMESCALE_B, MIN_BRI, MAX_BRI)
#                       with_transition_time(data, TRANSITION)
#                     end
#                   end

#       iterator.each do
#         Curl::Multi.http(requests.dup, MULTI_OPTIONS) do
#         end

#         global_results.add_from(results)
#         results.clear!

#         sleep(BETWEEN_SLEEP) unless BETWEEN_SLEEP == 0
#       end
#     end
#   end
# end

# # Wait for threads to finish initializing...
# sleep 0.01 while threads.find { |thread| thread.status != "sleep" }
# sleep 0.01 while sweep_thread.status != "sleep" if USE_SWEEP
# if SKIP_GC
#   important "Disabling garbage collection!  BE CAREFUL!"
#   GC.disable
# end
# debug "Threads are ready to go, waking them up."
# global_results.begin!
# sweep_thread.run if USE_SWEEP
# threads.each(&:run)

# trap("EXIT") do
#   if PROFILE_RUN
#     result  = RubyProf.stop
#     printer = RubyProf::CallStackPrinter.new(result)
#     File.open("results.html", "w") do |fh|
#       printer.print(fh)
#     end
#   end
#   global_results.done!
#   print_results(global_results)
# end

# threads.each(&:join)
# sweep_thread.terminate if USE_SWEEP

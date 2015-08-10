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
require_relative "./lib/node"
require_relative "./lib/root_node"
require_relative "./lib/transform_node"
require_relative "./lib/const_simulation"
require_relative "./lib/perlin_simulation"
require_relative "./lib/wave2_simulation"
require_relative "./lib/contrast_transform"
require_relative "./lib/range_transform"
require_relative "./lib/spotlight_transform"

###############################################################################
# Profiling and Debugging
###############################################################################
PROFILE_RUN = env_int("PROFILE_RUN", true) != 0
VERBOSE     = env_int("VERBOSE")
SKIP_GC     = !!env_int("SKIP_GC")
DEBUG_FLAGS = Hash[(ENV["DEBUG_NODES"] || "")
              .split(/\s*,\s*/)
              .map(&:upcase)
              .map { |nn| [nn, true] }]

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
USE_SWEEP       = (env_int("USE_SWEEP", true) || 1) != 0
SWEEP_LENGTH    = 2.0

TRANSITION      = env_float("TRANSITION") || 0.4 # In seconds, 1/10th sec. prec!

# Ballpark estimation of Jen's palette:
MIN_HUE         = env_int("MIN_HUE", true) || 48_000
MAX_HUE         = env_int("MAX_HUE", true) || 51_000
MIN_BRI         = env_float("MIN_BRI") || 0.25
MAX_BRI         = env_float("MAX_BRI") || 0.75

WAVE2_SCALE_X   = env_float("WAVE2_SCALE_X") || 0.1
WAVE2_SCALE_Y   = env_float("WAVE2_SCALE_Y") || 1.0
WAVE2_SPEED     = Vector2.new(x: WAVE2_SCALE_X, y: WAVE2_SCALE_Y)

PERLIN_SCALE_Y  = env_float("PERLIN_SCALE_Y") || 4.0
PERLIN_SPEED    = Vector2.new(x: 0.1, y: PERLIN_SCALE_Y)

# TODO: Run all simulations, and use a mixer to blend between them...
num_lights = CONFIG["main_lights"].length
lights_for_threads  = in_groups(CONFIG["main_lights"])
NODES = {}
# Root nodes (don't act as modifiers on other nodes' output):
       NODES["CONST"]      = ConstSimulation.new(lights: num_lights)
       NODES["WAVE2"]      = Wave2Simulation.new(lights: num_lights, speed: WAVE2_SPEED)
last = NODES["PERLIN"]     = PerlinSimulation.new(lights: num_lights, speed: PERLIN_SPEED)

# Transform nodes (act as a chain of modifiers):
# TODO: Parameterize a few more things like function/iterations below.
last = NODES["STRETCHED"]  = ContrastTransform.new(function:   Perlin::Curve::CUBIC, # LINEAR, CUBIC, QUINTIC -- don't bother using iterations>1 with LINEAR!
                                                   iterations: 3,
                                                   source:     last)
# Create one control group here per "quadrant"...
t_index = 0
lights_for_threads.each do |(_bridge_name, lights)|
  mask = [false] * num_lights
  lights.map(&:first).each { |idx| mask[idx] = true }
  last = RangeTransform.new(initial_min: MIN_BRI,
                            initial_max: MAX_BRI,
                            source:      last,
                            mask:        mask)
  NODES["SHIFTED_#{t_index}"]  = last
  t_index                     += 1
end
last = NODES["SPOTLIT"]    = SpotlightTransform.new(source: last)
# The end node that will be rendered to the lights:
FINAL_RESULT               = NODES["SPOTLIT"]

NODES.each do |name, node|
  node.debug = DEBUG_FLAGS[name]
end

###############################################################################
# Operational Configuration
###############################################################################
ITERATIONS = env_int("ITERATIONS", true) || 0

###############################################################################
# Main Simulation
###############################################################################
if PROFILE_RUN
  require "ruby-prof"
  RubyProf.measure_mode = RubyProf::ALLOCATIONS
  RubyProf.start
end

if ITERATIONS > 0
  debug "Running for #{ITERATIONS} iterations."
else
  debug "Running until we're killed.  Send SIGHUP to terminate with stats."
end

global_results = Results.new

Thread.abort_on_exception = false

INTERACTION = Launchpad::Interaction.new

class BarControl
  BLACK = { r: 0,    g: 0,    b: 0    }.freeze
  WHITE = { r: 0x3F, g: 0x3F, b: 0x3F }.freeze

  attr_accessor :on_change
  attr_reader :value

  def initialize(x:, y:, height:, on:, off:, down:, on_change: nil, value: 0)
    @x          = x
    @y          = y
    @height     = height
    @max_v      = height - 1
    @on         = BLACK.merge(on)
    @off        = BLACK.merge(off)
    @down       = BLACK.merge(down)
    @value      = value
    @on_change  = on_change

    INTERACTION.response_to(:grid, :both, x: @x, y: (@y..(@y + @max_v))) do |inter, action|
      guard_call("BarControl(#{@x},#{@y})") do
        xx = action[:x]
        yy = action[:y]
        if action[:state] == :down
          update(yy - @y)
          inter.device.change_grid(xx, yy, @down[:r], @down[:g], @down[:b])
          @on_change.call(@value) if @on_change
        else
          render
        end
      end
    end
  end

  def update(value)
    @value = value
    render
  end

  def render
    val = @value
    val = @height - 1 if val >= @height
    (0..@value).each do |yy|
      INTERACTION.device.change_grid(@x, @y + yy, @on[:r], @on[:g], @on[:b])
    end
    ((val+1)..@max_v).each do |yy|
      INTERACTION.device.change_grid(@x, @y + yy, @off[:r], @off[:g], @off[:b])
    end
  end
end

# Brightness range controls:
int_on      = { r: 0x27,          b: 0x3F }
int_off     = { r: 0x02,          b: 0x04 }
int_down    = { r: 0x27, g: 0x10, b: 0x3F }
int_states  = [ BarControl.new(x: 0, y: 4, height: 4, on: int_on, off: int_off, down: int_down),
                BarControl.new(x: 1, y: 4, height: 4, on: int_on, off: int_off, down: int_down),
                BarControl.new(x: 2, y: 4, height: 4, on: int_on, off: int_off, down: int_down),
                BarControl.new(x: 3, y: 4, height: 4, on: int_on, off: int_off, down: int_down) ]
int_values  = [ [0.20, 0.30],
                [0.30, 0.45],
                [0.45, 0.65],
                [0.65, 1.00] ]
int_states.each_with_index do |ctrl, idx|
  ctrl.on_change = proc do |val|
    puts "Intensity Controller ##{idx} => #{val}"
    NODES["SHIFTED_#{idx}"].set_range(int_values[val][0], int_values[val][1])
  end
end

input_thread = Thread.new do
  guard_call("Input Handler Setup") do
    Thread.stop
    # (0..7).each do |x|
    #   (0..7).each do |y|
    #     r, g, b = 0x00, x + 0x10, y + 0x10
    #     next if (0..3).include?(x) && (4..7).include?(y)
    #     INTERACTION.device.change_grid(x, y, r, g, b)
    #     sleep 0.001
    #   end
    # end
    # TODO: This isn't setting the actual light state properly.  AUGH!
    int_states.each { |ctrl| ctrl.update(0) }

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
      end
    end
  end
end

# Wait for threads to finish initializing...
sleep 0.01 while threads.find { |thread| thread.status != "sleep" }
sleep 0.01 while sweep_thread.status != "sleep" if USE_SWEEP
sleep 0.01 while sim_thread.status != "sleep"
sleep 0.01 while input_thread.status != "sleep"
if SKIP_GC
  important "Disabling garbage collection!  BE CAREFUL!"
  GC.disable
end
debug "Threads are ready to go, waking them up."
global_results.begin!
sim_thread.run
sweep_thread.run if USE_SWEEP
threads.each(&:run)
input_thread.run

trap("EXIT") do
  guard_call("Exit Handler") do
    global_results.done!
    print_results(global_results)
    (0..7).each do |x|
      (0..7).each do |y|
        INTERACTION.device.change_grid(x, y, 0x00, 0x00, 0x00)
        sleep 0.001
      end
    end

    if PROFILE_RUN
      result  = RubyProf.stop
      printer = RubyProf::CallStackPrinter.new(result)
      File.open("results.html", "w") do |fh|
        printer.print(fh)
      end
    end
    index = 0
    NODES.each do |name, node|
      next unless DEBUG_FLAGS[name]
      node.snapshot_to!("%02d_%s.png" % [index, name.downcase])
      index += 1
    end
  end
end

threads.each(&:join)
input_thread.terminate
sweep_thread.terminate if USE_SWEEP
sim_thread.terminate

lib = File.expand_path("../", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

# We shave 1/6th of a sec off launch time by not doing the following, but it
# presumes the user is using RVM properly to isolate the gem env, and that
# there are no git/path-based gems in the Gemfile:
# require "rubygems"
# require "bundler/setup"

require "erb"
require "yaml"
require "logger-better"
require "thread"

# System for building interesting, dynamic lighting effects for the Philips Hue,
# using the Novation Launchpad for control.
module SparkleMotion
  def self.logger; @logger; end

  def self.init!
    @logger          = Logger::Better.new(STDOUT)
    @logger.level    = (ENV["SPARKLEMOTION_LOGLEVEL"] || "info").downcase.to_sym
    @logger.progname = caller.last.split(":", 2).first.split(%r{/}).last
  end

  # Load code for talking to Philips Hue lighting system.
  HUE_API_DEPS = ["sparkle_motion/results",
                  "sparkle_motion/hue/http",
                  "sparkle_motion/hue/lazy_request_config"]
  HUE_DISCOVERY_DEPS = ["frisky/ssdp",
                        "sparkle_motion/hue/ssdp"]
  def self.use_hue!(discovery: false, api: false)
    HUE_API_DEPS.each { |name| require name } if api

    return unless discovery
    HUE_DISCOVERY_DEPS.each { |name| require name }
    Frisky.logging_enabled = false # Frisky is super verbose
  end

  # Load code for graph-structured effect generation.
  GRAPH_DEPS = ["perlin_noise",
                # Base classes:
                "sparkle_motion/node",
                "sparkle_motion/nodes/generator",
                "sparkle_motion/nodes/transform",
                # Simulation root nodes:
                "sparkle_motion/nodes/generators/const",
                "sparkle_motion/nodes/generators/perlin",
                "sparkle_motion/nodes/generators/wave2",
                # Simulation transform nodes:
                "sparkle_motion/nodes/transforms/contrast",
                "sparkle_motion/nodes/transforms/range",
                "sparkle_motion/nodes/transforms/spotlight",
                "sparkle_motion/nodes/transforms/slice",
                "sparkle_motion/nodes/transforms/join"]
  def self.use_graph!; GRAPH_DEPS.each { |name| require name }; end

  # Load code/widgets for Novation LaunchPad and Numark Orbit.
  WIDGET_DEPS = ["ostruct",
                 "sparkle_motion/widgets/screen_set",
                 "sparkle_motion/widgets/screen",
                 "sparkle_motion/widgets/tab_set",
                 "sparkle_motion/launch_pad/widget",
                 "sparkle_motion/launch_pad/widgets/toggle",
                 "sparkle_motion/launch_pad/widgets/horizontal_slider",
                 "sparkle_motion/launch_pad/widgets/vertical_slider",
                 "sparkle_motion/launch_pad/widgets/radio_group",
                 "sparkle_motion/launch_pad/widgets/button"]
  def self.use_widgets!; WIDGET_DEPS.each { |name| require name }; end

  INPUT_DEPS = ["surface_master"]
  def self.use_input!; INPUT_DEPS.each { |name| require name }; end

  CLI_DEPS = ["sparkle_motion/cli/argument_parser"]
  def self.use_cli!; CLI_DEPS.each { |name| require name }; end

  # Load code/widgets for processing audio data and interacting with audio devices.
  AUDIO_DEPS = ["coreaudio",
                "numru/fftw3",
                "sparkle_motion/audio/input_stream",
                "sparkle_motion/audio/device_input_stream",
                "sparkle_motion/audio/file_input_stream",
                "sparkle_motion/audio/output_stream",
                "sparkle_motion/audio/device_output_stream",
                "sparkle_motion/audio/band_pass_filter",
                "sparkle_motion/audio/stream_reporter",
                "sparkle_motion/audio/stream_filter"]
  def self.use_audio!; AUDIO_DEPS.each { |name| require name }; end

  CONFIG_DEPS = ["sparkle_motion/vector2",
                 "sparkle_motion/launch_pad/color",
                 "sparkle_motion/config",
                 "sparkle_motion/light_config"]
  def self.use_config!; CONFIG_DEPS.each { |name| require name }; end
end

require "sparkle_motion/version"
require "sparkle_motion/flow_control"
require "sparkle_motion/task"
require "sparkle_motion/managed_task"
require "sparkle_motion/unmanaged_task"
require "sparkle_motion/tick_task"
require "sparkle_motion/env"
require "sparkle_motion/stop_watch"

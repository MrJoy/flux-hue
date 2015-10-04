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

# System for building interesting, dynamic lighting effects for the Philips Hue,
# using the Novation Launchpad for control.
module SparkleMotion
  def self.logger; @logger; end

  def self.init!
    @logger         = Logger::Better.new(STDOUT)
    @logger.level   = (ENV["SPARKLEMOTION_LOGLEVEL"] || "info").downcase.to_sym
    @logger.progname = caller.last.split(":", 2).first.split(%r{/}).last
  end

  # Load code for talking to Philips Hue lighting system.
  def self.use_hue!(discovery: false, api: false)
    if api
      require "sparkle_motion/results"
      require "sparkle_motion/hue/http"
      require "sparkle_motion/hue/lazy_request_config"
    end

    if discovery
      require "frisky/ssdp"
      Frisky.logging_enabled = false # Frisky is super verbose

      require "sparkle_motion/hue/ssdp"
    end
  end

  # Load code for graph-structured effect generation.
  def self.use_graph!
    require "perlin_noise"

    # Base classes:
    require "sparkle_motion/node"
    require "sparkle_motion/nodes/generator"
    require "sparkle_motion/nodes/transform"

    # Simulation root nodes:
    require "sparkle_motion/nodes/generators/const"
    require "sparkle_motion/nodes/generators/perlin"
    require "sparkle_motion/nodes/generators/wave2"

    # Simulation transform nodes:
    require "sparkle_motion/nodes/transforms/contrast"
    require "sparkle_motion/nodes/transforms/range"
    require "sparkle_motion/nodes/transforms/spotlight"
  end

  def self.use_widgets!
    require "ostruct"
    require "sparkle_motion/launch_pad/widget"
    require "sparkle_motion/launch_pad/widget/toggle"
    require "sparkle_motion/launch_pad/widgets/horizontal_slider"
    require "sparkle_motion/launch_pad/widgets/vertical_slider"
    require "sparkle_motion/launch_pad/widgets/radio_group"
    require "sparkle_motion/launch_pad/widgets/button"
  end

  # Load code/widgets for Novation LaunchPad and Numark Orbit.
  def self.use_input!
    require "surface_master"
  end

  # Load code/widgets for processing audio data and interacting with audio devices.
  def self.use_audio!
    require "thread"
    require "coreaudio"

    require "sparkle_motion/audio/input_stream"
    require "sparkle_motion/audio/device_input_stream"
    require "sparkle_motion/audio/file_input_stream"

    require "sparkle_motion/audio/output_stream"
    require "sparkle_motion/audio/device_output_stream"

    require "sparkle_motion/audio/band_pass_filter"
  end
end

require "sparkle_motion/version"
require "sparkle_motion/flow_control"
require "sparkle_motion/config"
require "sparkle_motion/light_config"
require "sparkle_motion/env"

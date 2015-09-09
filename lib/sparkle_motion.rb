lib = File.expand_path("../", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

# We shave 1/6th of a sec off launch time by not doing the following, but it
# presumes the user is using RVM properly to isolate the gem env, and that
# there are no git/path-based gems in the Gemfile:
# require "rubygems"
# require "bundler/setup"

require "yaml"
require "logger-better"
require "set"
require "ostruct"

# System for building interesting, dynamic lighting effects for the Philips Hue,
# using the Novation Launchpad for control.
module SparkleMotion
  def self.logger; @logger; end

  def self.init!(name)
    @logger         = Logger::Better.new(STDOUT)
    @logger.level   = (ENV["SPARKLEMOTION_LOGLEVEL"] || "info").downcase.to_sym
    @logger.progname = name
  end

  # Load code for talking to Philips Hue lighting system.
  def self.use_hue!(discovery: false, api: false)
    if api
      require "sparkle_motion/results"
      require "sparkle_motion/lazy_request_config"
    end

    if discovery
      require "sparkle_motion/hue/ssdp"
    end
  end

  # Load code for graph-structured effect generation.
  def self.use_graph!
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
    require "sparkle_motion/launch_pad/widget"
    require "sparkle_motion/launch_pad/widgets/horizontal_slider"
    require "sparkle_motion/launch_pad/widgets/vertical_slider"
    require "sparkle_motion/launch_pad/widgets/radio_group"
    require "sparkle_motion/launch_pad/widgets/button"
  end

  # Load code/widgets for Novation LaunchPad.
  def self.use_launchpad!
    require "launchpad"
  end
end

require "sparkle_motion/utility"
require "sparkle_motion/config"
require "sparkle_motion/env"
require "sparkle_motion/http"

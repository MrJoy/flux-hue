lib = File.expand_path("../", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

# We shave 1/6th of a sec off launch time by not doing the following, but it
# presumes the user is using RVM properly to isolate the gem env, and that
# there are no git/path-based gems in the Gemfile:
# require "rubygems"
# require "bundler/setup"

require "yaml"
require "logger-better"

# System for building interesting, dynamic lighting effects for the Philips Hue,
# using the Novation Launchpad for control.
module FluxHue
  def self.logger; @logger; end

  def self.init!(name)
    @logger         = Logger::Better.new(STDOUT)
    @logger.level   = (ENV["FLUX_LOGLEVEL"] || "info").downcase.to_sym
    @logger.progname = name
  end

  # Load code for talking to Philips Hue lighting system.
  def self.use_hue!(discovery: false, api: false)
    if api
      require "flux_hue/results"
      require "flux_hue/lazy_request_config"
    end

    if discovery
      require "flux_hue/hue/ssdp"
    end
  end

  # Load code for graph-structured effect generation.
  def self.use_graph!
    # Base classes:
    require "flux_hue/node"
    require "flux_hue/nodes/generator"
    require "flux_hue/nodes/transform"

    # Simulation root nodes:
    require "flux_hue/nodes/generators/const"
    require "flux_hue/nodes/generators/perlin"
    require "flux_hue/nodes/generators/wave2"

    # Simulation transform nodes:
    require "flux_hue/nodes/transforms/contrast"
    require "flux_hue/nodes/transforms/range"
    require "flux_hue/nodes/transforms/spotlight"
  end

  def self.use_widgets!
    require "flux_hue/widget"
    require "flux_hue/widgets/horizontal_slider"
    require "flux_hue/widgets/vertical_slider"
    require "flux_hue/widgets/radio_group"
    require "flux_hue/widgets/button"
  end

  # Load code/widgets for Novation LaunchPad.
  def self.use_launchpad!
    require "launchpad"
  end
end

require "flux_hue/utility"
require "flux_hue/config"
require "flux_hue/env"
require "flux_hue/http"

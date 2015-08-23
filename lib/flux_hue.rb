lib = File.expand_path("../", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "rubygems"
require "bundler/setup"
Bundler.setup

module FluxHue
  def self.logger; @logger; end

  def self.init!
    require "logger"
    require "active_support/all"
    require "flux_hue/config"
    require "flux_hue/env"

    @logger         = Logger.new(STDOUT)
    @logger.level   = Logger.const_get((ENV["FLUX_LOGLEVEL"] || "INFO").upcase)
  end

  # Load code for talking to Philips Hue lighting system.
  def self.use_hue!
    require "flux_hue/utility"
    require "flux_hue/results"
    require "flux_hue/http"
  end

  # Load code for graph-structured effect generation.
  def self.use_graph!
    # Base classes:
    require "flux_hue/node"
    require "flux_hue/nodes/simulation"
    require "flux_hue/nodes/transform"

    # Simulation root nodes:
    require "flux_hue/nodes/simulations/const"
    require "flux_hue/nodes/simulations/perlin"
    require "flux_hue/nodes/simulations/wave2"

    # Simulation transform nodes:
    require "flux_hue/nodes/transforms/contrast"
    require "flux_hue/nodes/transforms/range"
    require "flux_hue/nodes/transforms/spotlight"
  end

  # Load code/widgets for Novation LaunchPad.
  def self.use_launchpad!
    require "flux_hue/widget"
    require "flux_hue/widgets/horizontal_slider"
    require "flux_hue/widgets/vertical_slider"
    require "flux_hue/widgets/radio_group"
    require "flux_hue/widgets/button"
  end
end

lib = File.expand_path("../", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "rubygems"
require "bundler/setup"
Bundler.setup

# Crufty common code:
require "flux_hue/output"
require "flux_hue/config"
require "flux_hue/logging"
require "flux_hue/env"
require "flux_hue/utility"
require "flux_hue/results"
require "flux_hue/http"

# Base classes:
require "flux_hue/node"
require "flux_hue/nodes/simulation"
require "flux_hue/nodes/transform"
require "flux_hue/widget"

# Simulation root nodes:
require "flux_hue/nodes/simulations/const"
require "flux_hue/nodes/simulations/perlin"
require "flux_hue/nodes/simulations/wave2"

# Simulation transform nodes:
require "flux_hue/nodes/transforms/contrast"
require "flux_hue/nodes/transforms/range"
require "flux_hue/nodes/transforms/spotlight"

# Launchpad widgets:
require "flux_hue/widgets/horizontal_slider"
require "flux_hue/widgets/vertical_slider"
require "flux_hue/widgets/radio_group"
require "flux_hue/widgets/button"

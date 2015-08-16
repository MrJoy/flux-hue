require "rubygems"
require "bundler/setup"
Bundler.setup

# Crufty common code:
require_relative "./output"
require_relative "./config"
require_relative "./logging"
require_relative "./env"
require_relative "./utility"
require_relative "./results"
require_relative "./http"

# Base classes:
require_relative "./node"
require_relative "./nodes/simulation"
require_relative "./nodes/transform"
require_relative "./widget"

# Simulation root nodes:
require_relative "./nodes/simulations/const"
require_relative "./nodes/simulations/perlin"
require_relative "./nodes/simulations/wave2"

# Simulation transform nodes:
require_relative "./nodes/transforms/contrast"
require_relative "./nodes/transforms/range"
require_relative "./nodes/transforms/spotlight"

# Launchpad widgets:
require_relative "./widgets/horizontal_slider"
require_relative "./widgets/vertical_slider"
require_relative "./widgets/radio_group"
require_relative "./widgets/button"

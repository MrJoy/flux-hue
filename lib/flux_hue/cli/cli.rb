# TODO: Normalize output, error handling, etc.

# TODO: Failure handling for setting names/lights.
require "terminal-table"

module FluxHue
  module CLI
    # CLI interface to library functionality, via Thor.
    class CLI < Base
      register(Bridge, "bridges", "bridges", "Interact with Hue Bridges")
      register(Lights, "lights", "lights", "Interact with lights")
      register(Groups, "groups", "groups", "Interact with groups")
    end
  end
end

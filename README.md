# Sparkle Motion

Generative event lighting system using Philips Hue and Novation Launchpad.


## Installation

After cloning this repo, run:

```bash
brew install portmidi
bundle install
bin/discover.rb # Find all available bridges using SSDP.
# Edit `config.yml`, and register the username(s) in it with the relevant bridges.
bin/mark_lights.rb # Ensure your lights are physically arranged properly.
bin/on.rb # Switch all the lights on, and set saturation/etc to expected state.
bin/launch_all.sh # Run the simulation.
```

__TODO: Document how to register user with hub(s).__


## Usage

* `bin/discover.rb`: Discover all Philips Hue bridges on your network.
* `bin/launch_all.sh`: Runs the effect system with configuration settings for debugging, etc.  See source for details.
* `bin/mark_lights.rb`: Mark the lights to help ensure they're physically ordered properly.
* `bin/off.rb`: Turn all configured lights off.
* `bin/on.rb`: Turn all configured lights on.
* `bin/simulate.rb`: Run the effect system.

## Using the Code

* `bin/examples/tictactoe.rb`: A simple example of the Novation Launchpad widgets, and how to use/extend them.
* `bin/tools/color_scale.rb`: A small playground for defining color schemes for Novation LaunchPad widgets.


## Debugging

* `bin/tools/watch_memory.sh`: External monitor to keep an eye on the process size of `simulate.rb`.


## Configuration

__ TODO: Write me.__

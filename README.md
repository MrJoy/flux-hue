# Sparkle Motion

Generative event lighting system using Philips Hue and Novation Launchpad.


## Installation

After cloning this repo, run:

```bash
brew install portmidi
gem install sparkle_motion
sm-discover # Find all available bridges using SSDP.
# Create `config.yml`, and register the username(s) in it with the relevant bridges.
# You probably want to start with the one in this project's source repo as a baseline.
sm-mark-lights # Ensure your lights are physically arranged properly.
sm-on # Switch all the lights on, and set color to expected base state.
sparkle-motion # Run the simulation.
```

__TODO: Document how to register user with hub(s).__


## Usage

* `bin/sm-discover`: Discover all Philips Hue bridges on your network.
* `bin/sm-mark-lights`: Mark the lights distinctively to help ensure they're physically arranged properly.
* `bin/sm-off`: Turn all configured lights off.
* `bin/sm-on`: Turn all configured lights on, and set them to the base color.
* `bin/sm-simulate`: Run the effect system directly.  You probably want `sparkle-motion` instead.
* `bin/sparkle-motion`: Runs the effect system with configuration settings for debugging, and restarts it if the kick-in-the-head button is pressed.  See source for details.

## Using the Code

* `examples/tictactoe.rb`: A simple example of the Novation Launchpad widgets, and how to use/extend them.
* `tools/chunker.rb`: Helper for churning through `*.raw` files and preparing them for visualization.
* `tools/color_scale.rb`: A small playground for defining color schemes for Novation LaunchPad widgets.


## Debugging

* `bin/sm-watch-memory`: External monitor to keep an eye on the process size of `sm-simulate`.  Useful for debugging memory allocations and GC pressure.


## Configuration

__ TODO: Write me.__

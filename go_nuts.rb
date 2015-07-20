#!/usr/bin/env ruby
require "rubygems"
require "bundler/setup"
Bundler.setup
require "curb"

###############################################################################
# Timing Configuration
#
# Play with this to see how error rates are affected.
###############################################################################
ITERATIONS      = 20
SPREAD_SLEEP    = 0.007
TOTAL_SLEEP     = 0.1
FIXED_SLEEP     = 0.03
VARIABLE_SLEEP  = TOTAL_SLEEP - FIXED_SLEEP
TRANSITION_TIME = 0.0 # In seconds, 1/10th second precision!

###############################################################################
# System Configuration
#
# Set these according to the lights you have.
###############################################################################
BRIDGE_IP       = ENV["HUE_BRIDGE_IP"]
USERNAME        = "1234567890" # Default from our library.
# LIGHTS          = %w(30)
LIGHTS          = %w(1 2 6 7 8 9 10 11 12 13 14 15 17 18 19 20 21 22 23 26 27
                     28 30 33 34 35 36 37)

###############################################################################
# Effect
#
# Tweak this to change the visual effect.
###############################################################################
def random_hue; rand(16) * 4096; end

###############################################################################
###############################################################################
def hue_endpoint(light_id)
  "http://#{BRIDGE_IP}/api/#{USERNAME}/lights/#{light_id}/state"
end

def hue_request(hue, transition)
  %({"hue":#{hue},"transitiontime":#{(transition * 10.0).round(0)}})
end

def guard_call(light_id, &block)
  block.call
rescue StandardError => e
  puts "Exception for light #{light_id}, got:"
  puts "\t#{e.message}"
  puts "\t#{e.backtrace.join("\n\t")}"
end

puts "Mucking with #{LIGHTS.length} lights..."

successes = 0
failures  = 0
threads   = LIGHTS.map do |light_id|
  sleep SPREAD_SLEEP
  Thread.new do
    guard_call(light_id) do
      counter = 0
      while counter < 20
        counter += 1
        new_hue = random_hue
        result = system %(
          curl --tcp-nodelay \
            --request PUT \
            --silent \
            -d '#{hue_request(new_hue, TRANSITION_TIME)}' \
            '#{hue_endpoint(light_id)}' >/dev/null 2>&1
        )
        if result
          successes += 1
        else
          failures += 1
        end
        sleep(FIXED_SLEEP + rand(VARIABLE_SLEEP))
        # | grep -v success
        # sleep rand(0.075)+0.025
      end
    end
    puts "Finishing thread for light ##{light_id}."
  end
end

threads
  .map(&:run)
  .each(&:join)

requests = successes + failures
puts "Done."
puts "* #{requests} requests"
puts "* #{successes} successful"
puts "* #{failures} failed"
puts "* #{"%0.2f" % ((failures / requests.to_f) * 100)}% failure rate"

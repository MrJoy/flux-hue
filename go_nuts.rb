#!/usr/bin/env ruby
require "rubygems"
require "bundler/setup"
Bundler.setup
require "curb"
require "oj"

###############################################################################
# Timing Configuration
#
# Play with this to see how error rates are affected.
###############################################################################
THREAD_COUNT    = 4
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
def hue_base
  "http://#{BRIDGE_IP}"
end

def hue_endpoint(light_id)
  "#{hue_base}/api/#{USERNAME}/lights/#{light_id}/state"
end

def hue_request(light_id, hue, transition)
  data = { "hue"            => hue,
           "transitiontime" => (transition * 10.0).round(0) }

  { light_id:   light_id,
    url:        hue_endpoint(light_id),
    put_data:   Oj.dump(data) }
end

def guard_call(thread_idx, &block)
  block.call
rescue Exception => e
  puts "Exception for thread ##{thread_idx}, got:"
  puts "\t#{e.message}"
  puts "\t#{e.backtrace.join("\n\t")}"
end

puts "Mucking with #{LIGHTS.length} lights..."

MULTI_OPTIONS = { pipeline: true }

lights_for_threads = (1..THREAD_COUNT).map { [] }
idx = 0
LIGHTS.each do |light_id|
  lights_for_threads[idx] << light_id
  idx  += 1
  idx   = 0 if idx >= THREAD_COUNT
end

successes = 0
failures  = 0

threads = (1..THREAD_COUNT).map do |thread_idx|
  sleep SPREAD_SLEEP
  Thread.new do
    guard_call(thread_idx) do
      agent           = Curl::Multi.new
      agent.pipeline  = true
      counter         = 0
      while counter < ITERATIONS
        counter += 1
        requests  = LIGHTS
                    .map { |lid| hue_request(lid, random_hue, TRANSITION_TIME) }
                    .map do |req|
                      Curl::Easy.new(req[:url]) do |curl|
                        curl.put_data = req[:put_data]
                        # curl.on_body do |data|
                        #   puts "For URL: #{req[:url]}\n\t#{data}"
                        # end
                        curl.on_success { |_easy| successes += 1 }
                        curl.on_failure do |easy|
                          puts "ERROR for light ##{req[:light_id]} on"\
                            " thread ##{thread_idx}: #{easy.inspect}"
                          failures += 1
                        end
                      end
                    end
        requests.each { |req| agent.add(req) }
        agent.perform

        sleep(FIXED_SLEEP + rand(VARIABLE_SLEEP))
      end
    end
    puts "Finishing thread ##{thread_idx}."
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
puts "* #{'%0.2f' % ((failures / requests.to_f) * 100)}% failure rate"

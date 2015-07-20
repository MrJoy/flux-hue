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
MULTI_OPTIONS   = { pipeline:     false,
                    max_connects: 1 }
TIMEOUT         = 0
THREAD_COUNT    = 6
ITERATIONS      = 200
SPREAD_SLEEP    = 0 # 0.007
TOTAL_SLEEP     = 0 # 0.1
FIXED_SLEEP     = 0 # 0.03
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
env_lights      = ENV["LIGHTS"] ? ENV["LIGHTS"].split(/[\s,]+/).sort.uniq : []
env_lights      = nil if env_lights.length == 0
LIGHTS          = env_lights || %w(1 2 6 7 8 9 10 11 12 13 14 15 17 18 19 20 21
                                   22 23 26 27 28 30 33 34 35 36 37)

###############################################################################
# Effect
#
# Tweak this to change the visual effect.
###############################################################################
def random_hue; rand(16) * 4096; end

###############################################################################
###############################################################################
def hue_server; "http://#{BRIDGE_IP}"; end
def hue_base; "#{hue_server}/api/#{USERNAME}"; end
def hue_endpoint(light_id); "#{hue_base}/lights/#{light_id}/state"; end

def hue_request(light_id, hue, transition)
  data = { "hue"            => hue,
           "transitiontime" => (transition * 10.0).round(0) }

  { method:     :put,
    timeout:    TIMEOUT.to_f,
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

lights_for_threads = (1..THREAD_COUNT).map { [] }
idx                = 0
LIGHTS.each do |light_id|
  lights_for_threads[idx] << light_id
  idx  += 1
  idx   = 0 if idx >= THREAD_COUNT
end

mutex     = Mutex.new
failures  = 0
successes = 0

Thread.abort_on_exception = false
threads   = (0..(THREAD_COUNT - 1)).map do |thread_idx|
  thread = Thread.new do
    local_failures  = 0
    local_successes = 0
    lights          = lights_for_threads[thread_idx]
    puts "Thread ##{thread_idx}, handling #{lights.count} lights."
    sleep SPREAD_SLEEP unless SPREAD_SLEEP == 0

    handlers  = { on_failure: ->(*_) { printf "*"; local_failures   += 1 },
                  on_success: ->(*_) { printf "."; local_successes  += 1 } }

    Thread.pass
    guard_call(thread_idx) do
      counter             = 0
      while counter < ITERATIONS
        local_failures  = 0
        local_successes = 0
        requests  = lights
                    .map { |lid| hue_request(lid, random_hue, TRANSITION_TIME) }
                    .map { |req| req.merge(handlers) }

        Curl::Multi.http(requests.dup, MULTI_OPTIONS) do
          # Apparently performed for each request!
        end

        mutex.synchronize do
          puts "\n#{thread_idx}: requests=#{requests.count}, counter=#{counter}"
          failures  += local_failures
          successes += local_successes
        end

        counter  += 1
        sleep(FIXED_SLEEP + rand(VARIABLE_SLEEP)) unless TOTAL_SLEEP == 0
      end
      mutex.synchronize do
        puts "#{thread_idx}: sum=#{local_failures + local_successes}, counter=#{counter}"
      end
    end
  end
  thread.run
  thread
end

threads
  .each(&:wakeup)
  .each(&:join)

requests  = successes + failures

puts
puts "Done."
puts "* #{requests} requests"
puts "* #{successes} successful"
puts "* #{failures} failed"
puts "* #{'%0.2f' % ((failures / requests.to_f) * 100)}% failure rate"

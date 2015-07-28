#!/usr/bin/env ruby
# https://github.com/taf2/curb/tree/master/bench

# TODO: Play with fibers using the more involved `Curl::Multi` interface that
# TODO: gives us an idle callback.
#   f = Fiber.new do
#     meth(1) do
#       Fiber.yield
#     end
#   end
#   meth(2) do
#     f.resume
#   end
#   f.resume
#   p Thread.current[:name]

###############################################################################
# Early Initialization/Helpers
###############################################################################
require "rubygems"
require "bundler/setup"
Bundler.setup
require "perlin"
require "curb"
require "oj"

def env_int(name, allow_zero = false)
  return nil unless ENV.key?(name)
  tmp = ENV[name].to_i
  tmp = nil if tmp == 0 && !allow_zero
  tmp
end

def env_float(name)
  return nil unless ENV.key?(name)
  ENV[name].to_f
end

###############################################################################
# Janky Logging
###############################################################################
def prefixed(msg)
  msg = "#{CONFIG}: #{msg}" if msg && msg != ""
  puts msg
end

def error(msg); prefixed(msg); end
def debug(msg); prefixed(msg) if VERBOSE; end
def important(msg); prefixed(msg); end

###############################################################################
# Bridges and Lights
###############################################################################
COMMON_USERNAME = "1234567890"
BRIDGE_01       = { ip:       "192.168.2.8",
                    username: COMMON_USERNAME,
                    lights:   %w(37 36 26 17 19 35 21) }
BRIDGE_02       = { ip:       "192.168.2.45",
                    username: COMMON_USERNAME,
                    lights:   %w(16 18 15 11 13 14 12) }
BRIDGE_03       = { ip:       "192.168.2.46",
                    username: COMMON_USERNAME,
                    lights:   %w(1 2 3 4 7 5 6) }
BRIDGE_04       = { ip:       "192.168.2.51",
                    username: COMMON_USERNAME,
                    lights:   %w(1 2 3 4 5 6 7) }

LIGHTING_CONFIGS = {
  "Bridge-01"       => BRIDGE_01,
  "Bridge-02"       => BRIDGE_02,
  "Bridge-03"       => BRIDGE_03,
  "Bridge-04"       => BRIDGE_04,
  "Bridge-01-Solo"  => BRIDGE_01.dup.merge(lights: [BRIDGE_01[:lights].first]),
  "Bridge-02-Solo"  => BRIDGE_02.dup.merge(lights: [BRIDGE_02[:lights].first]),
  "Bridge-03-Solo"  => BRIDGE_03.dup.merge(lights: [BRIDGE_03[:lights].first]),
  "Bridge-04-Solo"  => BRIDGE_04.dup.merge(lights: [BRIDGE_04[:lights].first]),
}

###############################################################################
# Timing Configuration
#
# Play with this to see how error rates are affected.
###############################################################################

# TODO: Try to figure out how to set Curl::CURLOPT_TCP_NODELAY => true
# TODO: Disable Curl from sending keepalives by trying HTTP/1.0.

MULTI_OPTIONS   = { pipeline:         false,
                    max_connects:     (env_int("MAX_CONNECTS") || 6) }
EASY_OPTIONS    = { timeout:          5,
                    connect_timeout:  5,
                    follow_location:  false,
                    max_redirects:    0 }
THREAD_COUNT    = env_int("THREADS") || 1
ITERATIONS      = env_int("ITERATIONS", true) || 20

SPREAD_SLEEP    = env_float("SPREAD_SLEEP") || 0.05
BETWEEN_SLEEP   = env_float("BETWEEN_SLEEP") || 0.0

VERBOSE         = env_int("VERBOSE")

###############################################################################
# Effect
#
# Tweak this to change the visual effect.
###############################################################################
TRANSITION    = env_float("TRANSITION") || 0.0 # In seconds, 1/10th sec. prec!

# Ballpark estimation of Jen's palette:
MAX_HUE       = env_int("MIN_HUE", true) || 51_000
MIN_HUE       = env_int("MAX_HUE", true) || 48_000
MAX_SAT       = env_int("MIN_SAT", true) || 254
MIN_SAT       = env_int("MAX_SAT", true) || 212
MIN_BRI       = env_int("MIN_BRI", true) || 127
MAX_BRI       = env_int("MAX_BRI", true) || 254

INIT_HUE      = env_int("INIT_HUE", true) || 49_500
INIT_SAT      = env_int("INIT_SAT", true) || 127
INIT_BRI      = env_int("INIT_BRI", true) || 127

TIMESCALE_H   = env_float("TIMESCALE_H") || 1.0
TIMESCALE_S   = env_float("TIMESCALE_S") || 3.0
TIMESCALE_B   = env_float("TIMESCALE_B") || 5.0

HUE_FUNC      = ENV.key?("HUE_FUNC") ? ENV["HUE_FUNC"] : "wave"
SAT_FUNC      = ENV.key?("SAT_FUNC") ? ENV["SAT_FUNC"] : "none"
BRI_FUNC      = ENV.key?("BRI_FUNC") ? ENV["BRI_FUNC"] : "perlin"

PERSISTENCE   = 8.0
OCTAVES       = 8
BASIS_TIME    = Time.now.to_f # Large Y values frighten and confuse our
                              # Perlin generator...
SEED          = BASIS_TIME.to_i % 1000 # Large seeds frighten and confuse our
                                       # Perlin generator...
PERLIN        = Perlin::Generator.new(SEED, PERSISTENCE, OCTAVES)

def perlin(x, s, min, max)
  # Ugly hack because the Perlin lib we're using doesn't like extreme Y values,
  # apparently.  It starts spitting zeroes back at us.
  elapsed = Time.now.to_f - BASIS_TIME
  (((PERLIN[x, elapsed * s] + 1) * 0.5 * (max - min)) + min).to_i
end

def wave(_x, s, min, max)
  (((Math.sin(s * Time.now.to_f) + 1) * 0.5 * (max - min)) + min).to_i
end

HUE_GEN = {
  "perlin"  => proc { |l_id| perlin(l_id, TIMESCALE_H, MIN_HUE, MAX_HUE) },
  "wave"    => proc { |l_id| wave(l_id, TIMESCALE_H, MIN_HUE, MAX_HUE) },
}

SAT_GEN = {
  "perlin"  => proc { |l_id| perlin(l_id, TIMESCALE_S, MIN_SAT, MAX_SAT) },
  "wave"    => proc { |l_id| wave(l_id, TIMESCALE_S, MIN_SAT, MAX_SAT) },
}

BRI_GEN = {
  "perlin"  => proc { |l_id| perlin(l_id, TIMESCALE_B, MIN_BRI, MAX_BRI) },
  "wave"    => proc { |l_id| wave(l_id, TIMESCALE_B, MIN_BRI, MAX_BRI) },
}

###############################################################################
# Other Configuration
###############################################################################
SKIP_GC           = !!env_int("SKIP_GC")

###############################################################################
# Bring together defaults and env vars, initialize things, etc...
###############################################################################
CONFIG            = ARGV.shift || "Bridge-01"
BRIDGE_IP         = LIGHTING_CONFIGS[CONFIG][:ip]
USERNAME          = LIGHTING_CONFIGS[CONFIG][:username]

ramp_factor       = ENV["OVERRAMP"].to_i
ramp_factor       = (ramp_factor > 0) ? (THREAD_COUNT * ramp_factor) : 1
LIGHTS            = LIGHTING_CONFIGS[CONFIG][:lights].map(&:to_i) * ramp_factor

###############################################################################
# Helper Functions
###############################################################################
def validate_func_for!(component, value, functions)
  return if functions.key?(value)
  return if value == "none"
  error "Unknown value for #{component.upcase}_FUNC: `#{value}`!"
end

def validate_counts!(lights, threads)
  return if threads <= lights

  fail "Must have at least one light for every thread you want!"
end

def validate_max_sockets!(max_connects, threads)
  total_conns = max_connects * threads
  return if total_conns <= 6
  fail "No more than 6 connections are allowed by the hub at once!  You asked"\
    " for #{total_conns}!"
end

def message_count_for_functions(hue_func, sat_func, bri_func)
  counter = 0
  counter += 1 if HUE_GEN.key?(hue_func)
  counter += 1 if SAT_GEN.key?(sat_func)
  counter += 1 if BRI_GEN.key?(bri_func)
  counter = 2 if counter > 2
  counter
end

def hue_server; "http://#{BRIDGE_IP}"; end
def hue_base; "#{hue_server}/api/#{USERNAME}"; end
def hue_light_endpoint(light_id); "#{hue_base}/lights/#{light_id}/state"; end

def with_transition_time(data, transition)
  data.merge("transitiontime" => (transition * 10.0).round(0))
end

def make_req_struct(light_id, transition, data)
  tmp = { method:   :put,
          url:      hue_light_endpoint(light_id),
          put_data: Oj.dump(with_transition_time(data, transition)) }
  tmp.merge(EASY_OPTIONS)
end

def hue_init(light_id)
  make_req_struct(light_id, 0,  "on"  => true,
                                "bri" => INIT_BRI,
                                "sat" => INIT_SAT,
                                "hue" => INIT_HUE)
end

def hue_request(light_id, transition)
  data = {}
  data["hue"] = HUE_GEN[HUE_FUNC].call(light_id) if HUE_GEN[HUE_FUNC]
  data["sat"] = SAT_GEN[SAT_FUNC].call(light_id) if SAT_GEN[SAT_FUNC]
  data["bri"] = BRI_GEN[BRI_FUNC].call(light_id) if BRI_GEN[BRI_FUNC]

  make_req_struct(light_id, transition, data)
end

# rubocop:disable Lint/RescueException
def guard_call(thread_idx, &block)
  block.call
rescue Exception => e
  error("Exception for thread ##{thread_idx}, got:")
  error("\t#{e.message}")
  error("\t#{e.backtrace.join("\n\t")}")
end
# rubocop:enable Lint/RescueException

def in_groups(entities, num_groups)
  groups = (1..num_groups).map { [] }
  idx                = 0
  entities.each do |entity|
    groups[idx] << entity
    idx  += 1
    idx   = 0 if idx >= num_groups
  end

  groups
end

###############################################################################
# Main
###############################################################################
effective_thread_count    = THREAD_COUNT
num_lights                = LIGHTS.length
if THREAD_COUNT > num_lights
  important("Clamping to #{num_lights} threads because we have too few lights.")
  effective_thread_count  = num_lights
end
# validate_max_sockets!(MULTI_OPTIONS[:max_connects], effective_thread_count)

validate_func_for!("hue", HUE_FUNC, HUE_GEN)
validate_func_for!("sat", SAT_FUNC, SAT_GEN)
validate_func_for!("bri", BRI_FUNC, BRI_GEN)

msg_count = message_count_for_functions(HUE_FUNC, SAT_FUNC, BRI_FUNC)
debug "Mucking with #{num_lights} lights, across #{effective_thread_count}"\
  " threads with #{MULTI_OPTIONS[:max_connects]} connections each.  Expect"\
  " each update to send #{msg_count} ZigBee messages."

if ITERATIONS > 0
  reqs = num_lights * ITERATIONS
  debug "Running for #{ITERATIONS} iterations (requests == #{reqs})."
else
  debug "Running until we're killed.  Send SIGHUP to terminate with stats."
end

lights_for_threads  = in_groups(LIGHTS, effective_thread_count)
mutex               = Mutex.new
@hard_timeouts      = 0
@soft_timeouts      = 0
@failures           = 0
@successes          = 0

debug "Initializing lights..."
Curl::Multi.http(LIGHTS.sort.uniq.map { |lid| hue_init(lid) }, MULTI_OPTIONS) do |easy|
  if easy.response_code != 200
    error "Failed to initialize light (will try again): #{easy.url}"
    add(easy)
  end
end
sleep(0.5)

Thread.abort_on_exception = false
threads = (0..(effective_thread_count - 1)).map do |thread_idx|
  sleep SPREAD_SLEEP unless SPREAD_SLEEP == 0
  Thread.new do
    l_hto   = 0
    l_sto   = 0
    l_fail  = 0
    l_succ  = 0
    lights  = lights_for_threads[thread_idx]
    debug("Thread ##{thread_idx}, handling #{lights.count} lights.")

    # TODO: Get timing stats, figure out if timeouts are in ms or sec, capture
    # TODO: info about failure causes, etc.
    handlers  = { on_failure: lambda do |easy, _|
                                case easy.response_code
                                when 404
                                  # Hit Bridge hardware limit.
                                  l_fail += 1
                                  printf "*"
                                when 0
                                  # Hit timeout.
                                  l_hto += 1
                                  printf "-"
                                else
                                  error("WAT: #{easy.response_code}")
                                end
                              end,
                  on_success: lambda do |easy|
                                if easy.body =~ /error/
                                  # Hit bridge rate limit / possibly ZigBee
                                  # limit?.
                                  l_sto += 1
                                  printf "~"
                                else
                                  l_succ += 1
                                  printf "." if VERBOSE
                                end
                              end }

    Thread.stop
    guard_call(thread_idx) do
      counter = 0
      while (ITERATIONS > 0) ? (counter < ITERATIONS) : true
        l_hto     = 0
        l_sto     = 0
        l_fail    = 0
        l_succ    = 0
        requests  = lights
                    .map { |lid| hue_request(lid, TRANSITION) }
                    .map { |req| req.merge(handlers) }

        Curl::Multi.http(requests.dup, MULTI_OPTIONS) do # |easy|
          # Apparently performed for each request?  Or when idle?  Or...

          # dns_cache_timeout head header_size header_str headers
          # http_connect_code last_effective_url last_result low_speed_limit
          # low_speed_time num_connects on_header os_errno redirect_count
          # request_size

          # app_connect_time connect_time name_lookup_time pre_transfer_time
          # start_transfer_time total_time

          # Bytes/sec, I think:
          # download_speed upload_speed

          # The following are all Float, and downloaded_content_length can be
          # -1.0 when a transfer times out(?).
          # downloaded_bytes downloaded_content_length uploaded_bytes
          # uploaded_content_length
        end

        mutex.synchronize do
          @hard_timeouts += l_hto
          @soft_timeouts += l_sto
          @failures      += l_fail
          @successes     += l_succ
        end

        counter += 1
        sleep(BETWEEN_SLEEP) unless BETWEEN_SLEEP == 0
      end
    end
  end
end

sleep 0.01 while threads.find { |thread| thread.status != "sleep" }
if SKIP_GC
  debug("Disabling garbage collection!  BE CAREFUL!")
  GC.disable
end
debug("Threads are ready to go, waking them up!")
@start_time = Time.now.to_f
threads.each(&:wakeup)

def compute_results(start_time, end_time, successes, failures, hard_timeouts, soft_timeouts)
  elapsed   = end_time - start_time
  requests  = successes + failures + hard_timeouts + soft_timeouts
  [elapsed, requests]
end

def ratio(num, denom); (num / denom.to_f).round(3); end

def print_results(elapsed, requests, successes, failures, hard_timeouts, soft_timeouts)
  important("")
  important("* #{requests} requests (#{ratio(requests, elapsed)}/sec)")
  important("* #{successes} successful (#{ratio(successes, elapsed)}/sec)")
  important("* #{failures} failed (#{ratio(failures, elapsed)}/sec)")
  important("* #{hard_timeouts} hard timeouts (#{ratio(hard_timeouts, elapsed)}/sec)")
  important("* #{soft_timeouts} soft timeouts (#{ratio(soft_timeouts, elapsed)}/sec)")
  all_failures = failures + hard_timeouts + soft_timeouts
  important("* #{ratio(all_failures * 100, requests)}% failure rate")
  suffix = " (#{ratio(elapsed, ITERATIONS)}/iteration)" if ITERATIONS > 0
  important("* #{elapsed.round(3)} seconds elapsed#{suffix}")
end

def show_results
  elapsed, requests = compute_results(@start_time,
                                      Time.now.to_f,
                                      @successes,
                                      @failures,
                                      @hard_timeouts,
                                      @soft_timeouts)
  print_results(elapsed, requests, @successes, @failures, @hard_timeouts, @soft_timeouts)
  exit 0
end

trap("HUP") { show_results }

threads.each(&:join)
show_results

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
  tmp = ENV[name].to_f
  (tmp == 0.0) ? nil : tmp
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

LIGHTING_CONFIGS = {
  "Bridge-01" => {
    ip:       "192.168.2.8",
    username: "1234567890",
    color:    %w(37 36 26 17 19 35 21),
    dimmable: %w(),
  },
  "Bridge-02" => {
    ip:       "192.168.2.45",
    username: "1234567890",
    color:    %w(16 18 15 11 13 14 12),
    dimmable: %w(),
  },
  "Bridge-03" => {
    ip:       "192.168.2.46",
    username: "1234567890",
    color:    %w(1 2 3 4 7 5 6),
    dimmable: %w(),
  },
  "Bridge-01-Only1" => {
    ip:       "192.168.2.8",
    username: "1234567890",
    color:    (["37"] * 30),
    dimmable: %w(),
  },
  "Bridge-02-Only1" => {
    ip:       "192.168.2.45",
    username: "1234567890",
    color:    (["16"] * 30),
    dimmable: %w(),
  },
  "Bridge-03-Only1" => {
    ip:       "192.168.2.46",
    username: "1234567890",
    color:    (["1"] * 30),
    dimmable: %w(),
  },
}

###############################################################################
# Timing Configuration
#
# Play with this to see how error rates are affected.
###############################################################################

# Curl::CURLOPT_TCP_NODELAY => true

MULTI_OPTIONS   = { pipeline:         false,
                    max_connects:     (env_int("MAX_CONNECTS") || 6) }
EASY_OPTIONS    = { timeout:          5,
                    connect_timeout:  5,
                    follow_location:  false,
                    max_redirects:    0 }
THREAD_COUNT    = env_int("THREADS") || 1
ITERATIONS      = env_int("ITERATIONS", true) || 20

SPREAD_SLEEP    = 0.05 # 0.007
TOTAL_SLEEP     = 0.0 # 0.1
FIXED_SLEEP     = 0.0 # 0.03
VARIABLE_SLEEP  = TOTAL_SLEEP - FIXED_SLEEP

VERBOSE         = env_int("VERBOSE")

###############################################################################
# Effect
#
# Tweak this to change the visual effect.
###############################################################################
TRANSITION    = env_float("TRANSITION") || 0.0 # In seconds, 1/10th sec. prec!

# Ballpark estimation of Jen's palette:
# Hue:        48000..51000
# Saturation:   168..255
# Brightness     ??..255
MAX_HUE       = 51_000
MIN_HUE       = 48_000
MAX_SAT       = 255
MIN_SAT       = 212
MIN_BRI       = env_int("MIN_BRI", true) || 0
MAX_BRI       = env_int("MAX_BRI") || 255

SATURATION    = env_int("SATURATION") || 255
HUE_POSITIONS = env_int("HUE_POSITIONS") || 16
BRI_POSITIONS = env_int("BRI_POSITIONS") || 8
TIMESCALE_H   = env_float("TIMESCALE_H") || 1.0
TIMESCALE_S   = env_float("TIMESCALE_S") || 3.0
TIMESCALE_B   = env_float("TIMESCALE_B") || 5.0

PERSISTENCE   = 8.0
OCTAVES       = 8
BASIS_TIME    = Time.now.to_f
SEED          = BASIS_TIME.to_i % 1000
PERLIN        = Perlin::Generator.new SEED, PERSISTENCE, OCTAVES

def p(x, s)
  # idx = (Math.sin(TIMESCALE_H * Time.now.to_f) + 1) * 0.5
  elapsed = Time.now.to_f - BASIS_TIME
  idx     = (PERLIN[x, elapsed * s] + 1) * 0.5
  # puts("<%0.5f>" % idx)
  idx
end

def random_hue(_light_id)
  # ((p(light_id, TIMESCALE_H) * (MAX_HUE - MIN_HUE)) + MIN_HUE).to_i
  (((Math.sin(TIMESCALE_H * Time.now.to_f) + 1) * 0.5 * (MAX_HUE - MIN_HUE)) + MIN_HUE).to_i
end

def random_sat(light_id)
  ((p(light_id, TIMESCALE_S) * (MAX_SAT - MIN_SAT)) + MIN_SAT).to_i
end

def random_bri(light_id)
  tmp = ((p(light_id, TIMESCALE_B) * (MAX_BRI - MIN_BRI)) + MIN_BRI).to_i
  # puts "<#{tmp}>"
  tmp
end

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
DIMMABLE_LIGHTS   = LIGHTING_CONFIGS[CONFIG][:dimmable].map(&:to_i)
COLOR_LIGHTS      = LIGHTING_CONFIGS[CONFIG][:color].map(&:to_i)

LIGHTS            = (COLOR_LIGHTS + DIMMABLE_LIGHTS) * ((ENV["OVERRAMP"].to_i != 0) ? THREAD_COUNT : 1)
IS_COLOR          = Hash[COLOR_LIGHTS.map { |n| [n.to_i, true] }]

###############################################################################
# Helper Functions
###############################################################################
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

def hue_server; "http://#{BRIDGE_IP}"; end
def hue_base; "#{hue_server}/api/#{USERNAME}"; end
def hue_endpoint(light_id); "#{hue_base}/lights/#{light_id}/state"; end

def with_transition_time(data, transition)
  data.merge("transitiontime" => (transition * 10.0).round(0))
end

def make_req_struct(light_id, transition, data)
  tmp = { method:   :put,
          url:      hue_endpoint(light_id),
          put_data: Oj.dump(with_transition_time(data, transition)) }
  tmp.merge(EASY_OPTIONS)
end

def hue_init(light_id)
  if IS_COLOR.key?(light_id)
    data  = { "on" => true, "bri" => 255, "sat" => SATURATION, "hue" => 0 }
  else
    data  = { "on" => true, "bri" => MIN_BRI }
  end
  make_req_struct(light_id, 0, data)
end

def hue_request(light_id, transition)
  if IS_COLOR.key?(light_id)
    data  = { "hue" => random_hue(light_id),
              "bri" => random_bri(light_id) }
  else
    data  = { "bri" => random_bri(light_id) }
  end
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
if THREAD_COUNT > LIGHTS.length
  error("Clamping to #{LIGHTS.length} threads because we have too few lights.")
  effective_thread_count  = LIGHTS.length
end
# validate_max_sockets!(MULTI_OPTIONS[:max_connects], effective_thread_count)

debug("Mucking with #{LIGHTS.length} lights, across #{effective_thread_count}"\
  " threads with #{MULTI_OPTIONS[:max_connects]} connections each.")

if ITERATIONS > 0
  reqs = LIGHTS.length * ITERATIONS
  debug("Running for #{ITERATIONS} iterations (requests == #{reqs}).")
else
  debug("Running until we're killed.  Send SIGHUP to terminate with stats.")
end

lights_for_threads  = in_groups(LIGHTS, effective_thread_count)
mutex               = Mutex.new
@hard_timeouts      = 0
@soft_timeouts      = 0
@failures           = 0
@successes          = 0

puts "#{CONFIG}: Initializing lights..." if VERBOSE
Curl::Multi.http(LIGHTS.sort.uniq.map { |lid| hue_init(lid) }, MULTI_OPTIONS) do |easy|
  if easy.response_code != 200
    puts "#{CONFIG}: Failed to initialize light (will try again): #{easy.url}"
    add(easy)
  end
end
sleep(0.5)

Thread.abort_on_exception = false
threads   = (0..(effective_thread_count - 1)).map do |thread_idx|
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
        sleep(FIXED_SLEEP + rand(VARIABLE_SLEEP)) unless TOTAL_SLEEP == 0
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
  important("* #{elapsed.round(3)} seconds elapsed (#{ratio(elapsed, ITERATIONS)}/iteration)")
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

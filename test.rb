#!/usr/bin/env ruby

# Socket::PF_INET
# Socket::SOCK_STREAM

# s = Socket.new Socket::INET, Socket::SOCK_STREAM
# s.connect Socket.pack_sockaddr_in(80, 'example.com')

# # Using TCPSocket
# s = TCPSocket.new 'example.com', 80

require "socket"

STATUS_EXP = %r{\AHTTP/(\d+\.\d+) (?<code>\d+)}

def set_light!(light, &callback)
  # Hue Bridge generally gives us:
  #   * Response status line
  #   * 3x cache-related header
  #   * Connection close indicator
  #   * 5x access control header
  #   * Content type
  #   * Body separator (blank)
  #   * Response body, as a one-liner
  # ... so we allocate 14 entries right off the bat to avoid reallocating any
  # under-the-hood blocks of memory, etc.
  timings = []
  timings << Time.now.to_f

  response  = Array.new(14)
  uri       = "/api/1234567890/lights/#{light}/state"
  timings << Time.now.to_f

  s = TCPSocket.new("192.168.2.10", 80)
  timings << Time.now.to_f

  body = %({"hue":#{callback.call},"transitiontime":0})
  len  = body.length
  s.puts("PUT #{uri} HTTP/1.0\nContent-Length: #{len}\n\n#{body}\n\n")
  timings << Time.now.to_f

  idx = 0
  loop do
    tmp = s.gets
    break unless tmp
    response[idx] = tmp
    idx += 1
  end
  timings << Time.now.to_f

  s.close
  timings << Time.now.to_f

  status  = nil
  body    = []
  state   = :find_status
  response.each do |line|
    case state
    when :find_status
      matches = STATUS_EXP.match(line)
      status = matches[:code].to_i if matches && matches[:code]
      state = :find_body
    when :find_body
      state = :capture_body if line == "\r\n"
    when :capture_body
      body << line
    end
  end
  timings << Time.now.to_f

  [status,
   body,
   timings[1..-1].zip(timings).map { |(a, b)| ((a - b) * 1000).round }]
end

LIGHTS    = [37, 36, 38, 39, 40, 35]
LAST_TIME = Array.new(LIGHTS.length)

def error?(status, body)
  return true if status != 200
  !!body.find { |line| line =~ /error/ }
end

start_time = Time.now.to_f
successes = 0
failures  = 0
trap("EXIT") do
  requests  = successes + failures
  end_time  = Time.now.to_f
  elapsed   = end_time - start_time
  puts
  puts "Results:      #{requests} requests in #{elapsed.round(2)} sec"
  puts "              #{successes} successes, #{failures} failures"
  puts "Performance:  #{(requests / elapsed).round(2)} req/sec"
  puts "Stability:    #{((successes / requests.to_f) * 100).round(1)}% succeeded"
  puts
  exit 0
end

iterations = 0
GC.disable
begin
  loop do
    break if iterations >= 30
    iterations += 1
    hue         = Random.rand(65_535)
    extra_wait  = 0
    LIGHTS.each do |light|
      status, body, _timings  = set_light!(light) { hue }
      failed                  = error?(status, body)
      if failed
        failures += 1
        extra_wait += 50
      else
        successes += 1
      end
      printf failed ? "-" : "*"
    end
    sleep 0.06 + (extra_wait / 1000.0)
    printf " (#{extra_wait}ms)" if extra_wait > 0
    puts
  end
rescue Interrupt
  puts "Goodbye."
end

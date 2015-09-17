#!/usr/bin/env ruby
require "yaml"
require "set"
require "chunky_png"
require "json"

def coalesce(item)
  [(item["start"] * 1000).round,
   (item["duration"] * 1000).round]
end

def safe_parse(raw)
  tmp = JSON.parse(raw)
  if tmp.is_a?(Hash) && tmp.key?("transitiontime")
    # Transition time is in 10ths of a second.
    tmp["transitiontime"] = tmp["transitiontime"] * 100
  end
  tmp
rescue StandardError
  raw
end

def organize_rest_result(data)
  result = false
  # The transitiontime component will always be true...
  filtered = data.reject { |datum| datum.values.first.keys.first =~ %r{/transitiontime\z} }
  result_codes = filtered.map(&:to_a).map(&:first).map(&:first).sort.uniq
  if result_codes.length == 1
    # Only one status.  Phew!
    result = (result_codes.first == "success")
  else
    # Not sure this outcome is actually *possible*, but the format
    # of the response from the Hue Bridge seems to allow for it...
    #
    # You'll know which parameter(s) failed by the type of the value:
    # If it's a `Hash`, there was an error.  Otherwise, it succeeded.
    puts "WAT: #{data.inspect}"
    result = nil
  end
  result
end

def chunk(items, step_size = 40)
  # TODO: This should be chunked at the granularity defined by SparkleMotion::Node::FRAME_PERIOD
  #
  # TODO: We... probably do not want to blow up memory like this, but rather,
  # TODO: round the time into frames, and when iterating over this, look at the
  # TODO: gap length and proceed accordingly.
  chunks_out = Set.new
  items.each do |item|
    start_bucket, duration = coalesce(item)
    (start_bucket..start_bucket + duration).step(step_size) do |x|
      chunks_out.add("payload" => item["payload"],
                     "success" => item["success"],
                     "time"    => (x * 1000).round)
    end
  end
  chunks_out
end

def perform_with_timing(msg, &action)
  printf "#{msg}..."
  before = Time.now.to_f
  action.call
ensure
  puts " #{(Time.now.to_f - before).round(2)} seconds."
end

def stringify_keys(hash); Hash[hash.map { |key, val| [key.to_s, val] }]; end

lines       = []
bucketed    = {}
good_events = {}
chunked     = { "base_time" => nil }
all_events  = Set.new
source      = ARGV.shift
dest        = "#{source.sub(/\.raw\z/, '')}.yml"

perform_with_timing "Parsing raw data" do
  File.open(source, "r") do |f|
    f.each_line do |line|
      # TODO: Uh, we need proper CSV parsing here...  And proper CSV generation.
      # TODO: In the meantime I'll cheat and rely on my knowledge that commas will
      # TODO: only appear in the payload.
      elts    = line.split(",", 4)
      parsed  = { "time"    => elts[0].to_f,
                  "action"  => elts[1],
                  "url"     => elts[2],
                  "payload" => safe_parse(elts[3]) }
      lines.push parsed
      bucketed[parsed["url"]] ||= []
      bucketed[parsed["url"]].push("time"    => parsed["time"],
                                   "action"  => parsed["action"],
                                   "payload" => parsed["payload"])
    end
  end
end

perform_with_timing "Organizing data" do
  bucketed.each do |url, events|
    events.each_with_index do |event, index|
      next unless event["action"] == "END"
      unless index > 0 && events[index - 1]["action"] == "BEGIN"
        # Calling this out because it would seriously bite us if it happened.
        puts "Ordering issue!  GAH!  Perhaps results got interleaved oddly?!"
        next
      end
      raw       = url.split("/")
      bridge    = raw[2]
      light_id  = raw[6].to_i
      # TODO: We'll need to pull config data to map this into a *logical* index!
      light     = [bridge, light_id].join("-")
      good_events[light] ||= []
      good_events[light].push("start"     => events[index - 1]["time"],
                              "duration"  => event["time"] - events[index - 1]["time"],
                              "payload"   => events[index - 1]["payload"],
                              "success"   => organize_rest_result(event["payload"]))
                              # light_id:      [bridge, light_id])
    end
  end
end

perform_with_timing "Extracting successful events" do
  base_times = []
  good_events.each do |k, v|
    v.sort_by! { |hsh| hsh["start"] }
    base_times << v[0]["start"]
    chunked[k] = chunk(good_events[k])
    all_events.merge chunked[k]
    # all_events[k] ||= []
    # all_events[k] += chunked[k]
  end
  chunked["base_time"] = (base_times.sort.first * 1000).round
end

# sorted = all_events.sort_by { |hsh| hsh[:time] }

# require "pry"
# binding.pry

simplified = perform_with_timing "Simplifying data for output" do
  Hash[chunked.map { |idx, data| [idx, data.is_a?(Set) ? data.to_a : data] }]
end

output = perform_with_timing "Converting data to YAML" do
  simplified.to_yaml
end

perform_with_timing "Writing #{dest}" do
  File.write(dest, output)
end

# size_x = chunked.values.map(&:count).max
# size_y = chunked.keys.last
# png = ChunkyPNG::Image.new(size_x, size_y, ChunkyPNG::Color::TRANSPARENT)

# Getting pretty close now. Sorted contains all the data, ordered by timestamp.

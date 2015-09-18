#!/usr/bin/env ruby
require "yaml"
require "set"
require "chunky_png"
require "json"

FRAME_TIME  = 40
SCALE_X     = 40
SCALE_Y     = 4 # About 10ms per pixel....

def in_ms(val); (val * 1000).round; end

def coalesce(item, base_time, frame_time)
  start_at = in_ms(item["start"]) - base_time
  duration = in_ms(item["duration"])
  # Return the starting *frame*...
  ((start_at + duration) / frame_time.to_f).round
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

def chunk(items, base_time, frame_time = FRAME_TIME)
  # TODO: This should be chunked at the granularity defined by SparkleMotion::Node::FRAME_PERIOD
  #
  # TODO: We... probably do not want to blow up memory like this, but rather,
  # TODO: round the time into frames, and when iterating over this, look at the
  # TODO: gap length and proceed accordingly.
  chunks_out = Set.new
  items.each do |item|
    start_frame = coalesce(item, base_time, frame_time)
    # TODO: Hrm.  Looking at duration is... not the right way to go.  We should
    # TODO: probably assume that the light begins changing at roughly (start + duration)
    # TODO: -- it definitely continues for some period of time towards the target value
    # TODO: where that period is defined by the transition time...

    # TODO: We need to interpolate, but we need the previous value as it existed
    # TODO: when we started.  I.E. it may or may not have gotten done
    # TODO: interpolating but wherever it had gotten to when we started
    # TODO: is the starting point for our interpolation...
    chunks_out.add("payload"     => item["payload"],
                   "success"     => item["success"],
                   "start_frame" => start_frame)
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
chunked     = {}
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
  good_events.each do |_k, v|
    v.sort_by! { |hsh| hsh["start"] }
    base_times << v[0]["start"]
  end
  base_time = (base_times.sort.first * 1000).round
  good_events.each do |k, _v|
    chunked[k] = chunk(good_events[k], base_time)
    all_events.merge chunked[k]
    # all_events[k] ||= []
    # all_events[k] += chunked[k]
  end
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

def to_color(val)
  ChunkyPNG::Color.rgba(val, val, val, 255)
end

# TODO: This needs to be computed in terms of start_frame AND transitiontime...
size_x  = simplified.keys.count * SCALE_X
size_y  = (simplified.values.map { |l| l.map { |m| m["start_frame"] }.last }.sort.last + 1) * SCALE_Y
png     = ChunkyPNG::Image.new(size_x, size_y, ChunkyPNG::Color::TRANSPARENT)
max_y   = size_y - 1
puts "Expected target size: #{size_x}x#{size_y}"
# require "pry"
# binding.pry
# TODO: Map the keys here into the index of lights!  Order by light position....
simplified.keys.sort.each_with_index do |light, l_idx|
  x_min = l_idx * SCALE_X
  x_max = (x_min + SCALE_X) - 1
  puts "#{x_min}..#{x_max}"
  last_bri = 0
  simplified[light].each_with_index do |cur_sample, s_idx|
    next_sample   = simplified[light][s_idx + 1]
    y_min         = cur_sample["start_frame"] * SCALE_Y
    y_transition  = cur_sample["payload"]["transitiontime"]
    if next_sample
      y_max = next_sample["start_frame"] * SCALE_Y
    else
      y_max = y_min + ((y_transition / FRAME_TIME).round * SCALE_Y)
    end
    y_max -= 1
    # puts "  #{cur_sample['start_frame']}: #{y_min}..#{y_max}"
    (x_min..x_max).each do |x|
      eff_y_max = (y_max > max_y) ? max_y : y_max
      (y_min..eff_y_max).each do |y|
        # TODO: Interpolation...
        last_bri = cur_sample["payload"]["bri"]
        png[x, y] = to_color(last_bri)
      end
    end

  end
end
png.save(dest.sub(/\.yml\z/, ".png"), interlace: false)
# Getting pretty close now. Sorted contains all the data, ordered by timestamp.

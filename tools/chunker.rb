#!/usr/bin/env ruby
require "yaml"
require "set"
require "chunky_png"

def coalesce(item, digits)
  [item[:start].round(digits),
   item[:duration].round(digits)]
end

def chunk(items, step_size = 0.1, digits = 1)
  chunks_out = Set.new
  items.each do |item|
    start_bucket, duration = coalesce(item, digits)
    (start_bucket..start_bucket + duration).step(step_size) do |x|
      # chunks_out.add(item.merge(time: x.round(digits)))
      chunks_out.add(payload_begin: item[:payload_begin],
                     payload_end:   item[:payload_end],
                     light_id:      item[:light_id],
                     time:          x.round(digits))
    end
  end
  chunks_out
end

lines       = []
bucketed    = {}
good_events = {}
chunked     = {}
all_events  = Set.new
source      = ARGV.shift
dest        = "#{source.sub(/\.raw\z/, '')}.yml"

printf "Parsing raw data..."
before = Time.now.to_f
File.open(source, "r") do |f|
  f.each_line do |line|
    # TODO: Uh, we need proper CSV parsing here...  And proper CSV generation.
    # TODO: In the meantime I'll cheat and rely on my knowledge that commas will
    # TODO: only appear in the payload.
    elts    = line.split(",", 4)
    parsed  = { time:    elts[0].to_f,
                action:  elts[1],
                url:     elts[2],
                payload: elts[3] }
    lines.push parsed
    bucketed[parsed[:url]] ||= []
    bucketed[parsed[:url]].push(time:     parsed[:time],
                                action:   parsed[:action],
                                payload:  parsed[:payload])
  end
end
puts " #{(Time.now.to_f - before).round(2)} seconds."

printf "Organizing data..."
before = Time.now.to_f
bucketed.each do |url, events|
  events.each_with_index do |event, index|
    next unless event[:action] == "END" && index > 0 && events[index - 1][:action] == "BEGIN"
    light_id = url.split("/")[6]
    good_events[light_id.to_i] ||= []
    good_events[light_id.to_i].push(start:         events[index - 1][:time],
                                    duration:      event[:time] - events[index - 1][:time],
                                    payload_begin: events[index - 1][:payload],
                                    payload_end:   event[:payload],
                                    light_id:      light_id.to_i)
  end
end
puts " #{(Time.now.to_f - before).round(2)} seconds."

printf "Extracting successful events..."
before = Time.now.to_f
good_events.each do |k, v|
  v.sort_by! { |hsh| hsh[:start] }
  chunked[k] = chunk(good_events[k])
  all_events.merge chunked[k]
end
puts " #{(Time.now.to_f - before).round(2)} seconds."

# sorted = all_events.sort_by { |hsh| hsh[:time] }

# require "pry"
# binding.pry

printf "Writing #{dest}..."
before = Time.now.to_f
File.write(dest, chunked.to_yaml)
puts " #{(Time.now.to_f - before).round(2)} seconds."

# size_x = chunked.values.map(&:count).max
# size_y = chunked.keys.last
# png = ChunkyPNG::Image.new(size_x, size_y, ChunkyPNG::Color::TRANSPARENT)

# Getting pretty close now. Sorted contains all the data, ordered by timestamp.

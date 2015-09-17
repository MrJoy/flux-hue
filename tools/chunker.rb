require "set"

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

File.open(source, "r") do |f|
  f.each_line do |line|
    elts    = line.split(",")
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

bucketed.each do |url, events|
  events.each_with_index do |event, index|
    next unless event[:action] == "END" && index > 0 && events[index - 1][:action] == "BEGIN"
    light_id = url.split("/")[6]
    good_events[light_id.to_i] ||= []
    good_events[light_id.to_i].push(start: events[index - 1][:time],
                          duration: event[:time] - events[index - 1][:time],
                          payload_begin: events[index - 1][:payload],
                          payload_end: event[:payload],
                          light_id: light_id.to_i)
  end
end

good_events.each do |k, v|
  v.sort_by! { |hsh| hsh[:start] }
  chunked[k] = chunk(good_events[k])
  all_events.merge chunked[k]
end

# sorted = all_events.sort_by { |hsh| hsh[:time] }

# require "pry"
# binding.pry

require "yaml"
File.write(dest, chunked.to_yaml)

# require "chunky_png"
# size_x = chunked.values.map(&:count).max
# size_y = chunked.keys.last
# png = ChunkyPNG::Image.new(size_x, size_y, ChunkyPNG::Color::TRANSPARENT)

# Getting pretty close now. Sorted contains all the data, ordered by timestamp.

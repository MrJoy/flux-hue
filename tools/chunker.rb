require "set"

def chunk(items, step_size = 0.1, digits = 1)
  chunks_out = Set.new
  items.each do |item|
    start_bucket = item[:start].round(digits)
    duration = item[:duration].round(digits)
    # chunks_out[start_bucket] ||= []
    (start_bucket..start_bucket + duration).step(step_size) do |x|
      x               = x.round(digits)
      chunks_out.add( {payload_begin: item[:payload_begin],
                         payload_end:   item[:payload_end],
                         light_id:      item[:light_id],
                         time:          x} )
    end
  end
  chunks_out
end

lines       = []
bucketed    = {}
good_events = {}
chunked     = {}
all_events  = Set.new

File.open("tmp/output.raw", "r") do |f|
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
    light_id = url.split('/')[6]
    good_events[light_id.to_i] ||= []
    good_events[light_id.to_i].push(start: events[index - 1][:time],
                          duration: event[:time] - events[index - 1][:time],
                          payload_begin: events[index - 1][:payload],
                          payload_end: event[:payload],
                          light_id: light_id.to_i)
  end
end

good_events.each do |k,v|
  good_events[k].sort_by! { |hsh| hsh[:start] }
  chunked[k] = chunk(good_events[k])
  all_events.merge chunked[k]
end

sorted = all_events.sort_by { |hsh| hsh[:time]}

require 'pry'
binding.pry

require 'chunky_png'
png = ChunkyPNG::Image.new(chunked.values.map(&:count).max, chunked.keys.last, ChunkyPNG::Color::TRANSPARENT)

# Getting pretty close now. Sorted contains all the data, ordered by timestamp.

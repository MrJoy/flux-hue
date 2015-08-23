def chunk(items, step_size = 0.1, digits = 1)
  chunks_out = {}
  items.each do |item|
    start_bucket = item[:start].round(digits)
    duration = item[:duration].round(digits)
    chunks_out[start_bucket] ||= []
    (start_bucket..start_bucket + duration).step(step_size) do |x|
      x = x.round(digits)
      chunks_out[x] ||= []
      chunks_out[x].push(payload_begin: item[:payload_begin], payload_end: item[:payload_end])
    end
  end
  chunks_out
end

lines = []
bucketed = {}
good_events = {}

File.open("/Users/jwagnerk/Desktop/debug_sample/output.raw", "r") do |f|
  f.each_line do |line|
    elts = line.split(",")
    parsed = {
      time: elts[0].to_f,
      action: elts[1],
      url: elts[2],
      payload: elts[3],
    }
    lines.push parsed
    bucketed[parsed[:url]] ||= []
    bucketed[parsed[:url]].push(time: parsed[:time], action: parsed[:action], payload: parsed[:payload])
  end
end

bucketed.each do |url, events|
  events.each_with_index do |event, index|
    if event[:action] == "END" && index > 0 && events[index - 1][:action] == "BEGIN"
      good_events[url] ||= []
      good_events[url].push(start: events[index - 1][:time],
                            duration: event[:time] - events[index - 1][:time],
                            payload_begin: events[index - 1][:payload],
                            payload_end: event[:payload])
    end
  end
end

# Use chunk on each element of the good_events hash.
#  chunk good_events["http://192.168.2.10/api/1234567890/lights/35/state"]

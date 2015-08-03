# rubocop:disable Lint/RescueException
def guard_call(bridge_name, &block)
  block.call
rescue Exception => e
  error bridge_name, "Exception for thread ##{bridge_name}, got:"
  error bridge_name, "\t#{e.message}"
  error bridge_name, "\t#{e.backtrace.join("\n\t")}"
end
# rubocop:enable Lint/RescueException

def in_groups(entities)
  groups = {}
  entities.each do |(bridge_name, light_id)|
    groups[bridge_name] ||= []
    groups[bridge_name] << light_id
  end

  groups.each do |bridge_name|
    indexed_lights = []
    groups[bridge_name].each_with_index do |light_id, index|
      indexed_lights << [index, light_id]
    end
    groups[bridge_name] = indexed_lights
  end

  groups
end

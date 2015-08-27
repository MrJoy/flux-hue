# TODO: Namespacing/classes/etc!

# rubocop:disable Lint/RescueException
def guard_call(prefix, &block)
  block.call
rescue Exception => e
  SparkleMotion.logger.error { "#{prefix}: Exception for #{prefix}: #{e.message}" }
  SparkleMotion.logger.error { "#{prefix}:\t#{e.backtrace.join("\n#{prefix}:\t")}" }
end
# rubocop:enable Lint/RescueException

def in_groups(entities)
  groups = {}
  entities.each do |(bridge_name, light_id)|
    groups[bridge_name] ||= []
    groups[bridge_name] << light_id
  end

  index = 0
  groups.each do |(bridge_name, lights)|
    indexed_lights = []
    lights.each do |light_id|
      indexed_lights << [index, light_id]
      index += 1
    end

    mask = [false] * entities.length
    indexed_lights.map(&:first).each { |idx| mask[idx] = true }

    groups[bridge_name] = [indexed_lights, mask]
  end

  groups
end

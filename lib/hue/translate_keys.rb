module Hue
  # Helpers for working with hash-based payloads from the Hue bridge.
  module TranslateKeys
    def translate_keys(hash, map)
      tmp = hash
            .map do |key, value|
              new_key = map[key.to_sym]
              key = new_key if new_key
              [key, value]
            end
      Hash[tmp]
    end

    def unpack_hash(hash, map)
      map.each do |local_key, remote_key|
        value = hash[remote_key.to_s]
        next unless value
        instance_variable_set("@#{local_key}", value)
      end
    end
  end
end

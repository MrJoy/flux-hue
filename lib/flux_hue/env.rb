def env_int(name, allow_zero = false)
  return nil unless ENV.key?(name)
  tmp = ENV[name].to_i
  tmp = nil if tmp == 0 && !allow_zero
  tmp
end

def env_float(name)
  return nil unless ENV.key?(name)
  ENV[name].to_f
end

def env_bool(name); (env_int(name, true) || 1) != 0; end

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

VERBOSE = env_int("VERBOSE") || 0

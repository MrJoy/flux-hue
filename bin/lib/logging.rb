def prefixed(bridge_name, msg)
  msg = "#{bridge_name}: #{msg}" if msg && msg != "" && bridge_name
  puts msg
end

def error(bridge_name = nil, msg); prefixed(bridge_name, msg); end
def debug(bridge_name = nil, msg); prefixed(bridge_name, msg) if VERBOSE; end
def important(bridge_name = nil, msg); prefixed(bridge_name, msg); end

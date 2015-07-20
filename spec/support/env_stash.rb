# Helper to ensure a clean execution environment during tests without
# destroying env vars the developer explicitly set.
module EnvStash
  # Don't let our tests go wonky because someone forget to unset some env vars.
  OVERRIDE_VARS = %w(HUE_BRIDGE_IP HUE_BRIDGE_USER HUE_SKIP_SSDP HUE_SKIP_NUPNP)

  def self.stash_overrides!(&block)
    stash = yank_keys!(OVERRIDE_VARS)
    block.call
  ensure
    stash.each do |key, value|
      ENV[key] = value
    end
  end

protected

  def self.yank_keys!(keys)
    stash = {}
    keys.each do |key|
      next unless ENV.key?(key)
      stash[key] = ENV[key]
      ENV.delete(key)
    end
    stash
  end
end

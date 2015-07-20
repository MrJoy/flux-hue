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

RSpec.describe FluxHue::Light do
  # rubocop:disable Metrics/LineLength

  %w(on hue saturation brightness color_temperature alert effect).each do |attribute|
    around do |test|
      EnvStash.stash_overrides!(&test)
    end

    before do
      stub_request(:get, %r{http://localhost/api/*})
        .to_return(body: '[{"success":true}]')

      stub_request(:put, %r{http://localhost/api*})
        .to_return(body: "[{}]")

      @client = FluxHue::Client.new(FluxHue::Bridge.all(ip: "localhost").first)
    end

    describe "##{attribute}=" do
      it "PUTs the new attribute value" do
        light = FluxHue::Light.new(client: @client, id: 0, state: {})

        light.send("#{attribute}=", 24)
        expect(a_request(:put, %r{http://localhost/api/.*/lights/0})).to have_been_made
      end
    end

    describe "#off?" do
      it "should return the opposite of state['on']" do
        state = { "on" => true }
        light = FluxHue::Light.new(client: @client, id: 0, state: state)
        expect(light.off?).to be false

        state = {}
        light = FluxHue::Light.new(client: @client, id: 0, state: state)
        expect(light.off?).to be true

        state = { "off" => false }
        light = FluxHue::Light.new(client: @client, id: 0, state: state)
        expect(light.off?).to be true
      end
    end
  end

  describe "#off?" do
    it "should return the opposite of state['on']" do
      state = { "on" => true }
      light = FluxHue::Light.new(client: @client, id: 0, state: state)
      expect(light.off?).to be false

      state = {}
      light = FluxHue::Light.new(client: @client, id: 0, state: state)
      expect(light.off?).to be true

      state = { "off" => false }
      light = FluxHue::Light.new(client: @client, id: 0, state: state)
      expect(light.off?).to be true
    end
  end
  # rubocop:enable Metrics/LineLength
end

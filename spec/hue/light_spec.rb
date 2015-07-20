RSpec.describe Hue::Light do
  # Don't let our tests go wonky because someone forget to unset some env vars.
  OVERRIDE_VARS = %w(HUE_BRIDGE_IP HUE_BRIDGE_USER HUE_SKIP_SSDP HUE_SKIP_NUPNP)
  # rubocop:disable Metrics/LineLength
  def stash_overrides!(&block)
    stash = {}
    begin
      OVERRIDE_VARS.each do |key|
        next unless ENV.key?(key)
        stash[key] = ENV[key]
        ENV.delete(key)
      end
      block.call
    ensure
      stash.each do |key, value|
        ENV[key] = value
      end
    end
  end

  %w(on hue saturation brightness color_temperature alert effect).each do |attribute|
    around do |test|
      stash_overrides!(&test)
    end

    before do
      stub_request(:get, %r{http://localhost/api/*})
        .to_return(body: '[{"success":true}]')

      stub_request(:put, %r{http://localhost/api*})
        .to_return(body: "[{}]")

      @client = Hue::Client.new(Hue::Bridge.all(ip: "localhost").first)
    end

    describe "##{attribute}=" do
      it "PUTs the new attribute value" do
        light = Hue::Light.new(client: @client, id: 0, state: {})

        light.send("#{attribute}=", 24)
        expect(a_request(:put, %r{http://localhost/api/.*/lights/0})).to have_been_made
      end
    end

    describe "#off?" do
      it "should return the opposite of state['on']" do
        state = { "on" => true }
        light = Hue::Light.new(client: @client, id: 0, state: state)
        expect(light.off?).to be false

        state = {}
        light = Hue::Light.new(client: @client, id: 0, state: state)
        expect(light.off?).to be true

        state = { "off" => false }
        light = Hue::Light.new(client: @client, id: 0, state: state)
        expect(light.off?).to be true
      end
    end
  end

  describe "#off?" do
    it "should return the opposite of state['on']" do
      state = { "on" => true }
      light = Hue::Light.new(client: @client, id: 0, state: state)
      expect(light.off?).to be false

      state = {}
      light = Hue::Light.new(client: @client, id: 0, state: state)
      expect(light.off?).to be true

      state = { "off" => false }
      light = Hue::Light.new(client: @client, id: 0, state: state)
      expect(light.off?).to be true
    end
  end
  # rubocop:enable Metrics/LineLength
end

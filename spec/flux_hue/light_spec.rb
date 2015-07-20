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

    describe "#on?" do
      it "should return the opposite of state['on']" do
        state = { "on" => true }
        light = FluxHue::Light.new(client: @client, id: 0, state: state)
        expect(light.on?).to be true

        state = {}
        light = FluxHue::Light.new(client: @client, id: 0, state: state)
        expect(light.on?).to be false

        state = { "off" => false }
        light = FluxHue::Light.new(client: @client, id: 0, state: state)
        expect(light.on?).to be false
      end
    end
  end

  describe "#on?" do
    it "should return the opposite of state['on']" do
      state = { "on" => true }
      light = FluxHue::Light.new(client: @client, id: 0, state: state)
      expect(light.on?).to be true

      state = {}
      light = FluxHue::Light.new(client: @client, id: 0, state: state)
      expect(light.on?).to be false

      state = { "off" => false }
      light = FluxHue::Light.new(client: @client, id: 0, state: state)
      expect(light.on?).to be false
    end
  end
  # rubocop:enable Metrics/LineLength
end

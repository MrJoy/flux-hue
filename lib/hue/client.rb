require 'net/http'
require 'json'

module Hue
  class Client
    attr_reader :username

    def initialize(username = Hue::USERNAME, ip = nil)
      unless USERNAME_RANGE.include?(username.length)
        raise InvalidUsername, "Usernames must be between #{USERNAME_RANGE.first} and #{USERNAME_RANGE.last}."
      end

      ip ||= ENV['HUE_BRIDGE_IP']
      bridge(ip)

      @username = username

      begin
        validate_user
      rescue Hue::UnauthorizedUser
        register_user
      end
    end

    def bridge(ip = nil)
      @bridge ||= begin
        if ip.nil?
          puts "INFO: Discovering bridge."
          # Pick the first one for now. In theory, they should all do the same thing.

          bridge = bridges.first
          raise NoBridgeFound unless bridge
          bridge
        else
          puts "INFO: Skipping bridge discovery."
          Bridge.new(self, {"ipaddress" => ip})
        end
      end
    end

    def bridges
      @bridges ||= begin
        puts "INFO: Trying SSDP search..."
        require 'playful/ssdp' unless defined?(Playful)
        # Playful is super verbose
        Playful.log = false

        devices = Playful::SSDP.search 'IpBridge'

        if devices.count == 0
          puts "INFO: SSDP failed, trying N-UPnP..."
          # UPnP failed, lets use N-UPnP
          bs = []
          JSON(Net::HTTP.get(URI.parse('https://www.meethue.com/api/nupnp'))).each do |hash|
            # Normalize our interface a bit...
            hash["ipaddress"] = hash.delete("internalipaddress")
            # The N-UPnP interface delivers an ID which is essentially the MAC
            # address, with two bytes injected in the middle.  To keep IDs sane
            # regardless of where we got them, we just reduce it to the MAC
            # address.
            tmp = hash.delete("id")
            hash["id"] = tmp[0..5] + tmp[10..15]
            bs << Bridge.new(self, hash)
          end
          bs
        else
          devices
            .uniq { |d| d[:location] }
            .map do |bridge|
              Bridge.new(self, {
                'id' => bridge[:usn].split(/:/, 3)[1].split(/-/).last,
                'name' => bridge[:st],
                'ipaddress' => URI.parse(bridge[:location]).host
              })
            end
        end
      end
    end

    def lights
      @lights ||= begin
        json = JSON(Net::HTTP.get(URI.parse(url)))
        json['lights'].map { |id, data| Light.new(self, id, data) }
      end
    end

    def groups
      @groups ||= begin
        json = JSON(Net::HTTP.get(URI.parse("#{url}/groups")))
        json.map { |id, data| Group.new(self, id, data) }
      end
    end

    def scenes
      @scenes ||= begin
        json = JSON(Net::HTTP.get(URI.parse("#{url}/scenes")))
        json.map { |id, data| Scene.new(self, id, data) }
      end
    end

    # TODO: Add support for specifying serial numbers.
    def add_lights
      uri = URI.parse("#{@client.url}/lights")
      http = Net::HTTP.new(uri.host)
      response = http.request_post(uri.path, nil)
      JSON(response.body).first
    end

    def light(id)
      id = id.to_s
      lights.find { |l| l.id == id }
    end


    def group(id)
      id = id.to_s
      groups.find { |g| g.id == id }
    end

    def scene(id)
      id = id.to_s
      scenes.find { |s| s.id == id }
    end

    def url; "#{bridge.url}/#{username}"; end

  private

    # TODO: Move user creation/validation to the bridge.

    # TODO: Prepopulate things with the response here, as we just pulled down
    # TODO: *everything* about the current state of the bridge!
    def validate_user
      response  = JSON(Net::HTTP.get(URI.parse(url)))
      response  = response.first if response.is_a? Array
      error     = response['error']

      raise get_error(error) if error

      response['success']
    end

    def register_user
      # TODO: Better devicetype value, and allow customizing it!
      data = {
        devicetype: 'Ruby',
        username:   username
      }

      uri       = URI.parse(bridge.url)
      http      = Net::HTTP.new(uri.host)
      response  = JSON(http.request_post(uri.path, JSON.dump(data)).body).first
      error     = response['error']

      raise get_error(error) if error

      response['success']
    end

    def get_error(error)
      # Find error class and return instance
      klass = Hue::ERROR_MAP[error['type']] || UnknownError
      klass.new(error['description'])
    end
  end
end

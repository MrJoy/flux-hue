require 'net/http'
require 'json'
require 'curb'

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
          puts "INFO: Discovering hub..."
          # Pick the first one for now. In theory, they should all do the same thing.

          bridge = bridges.first
          raise NoBridgeFound unless bridge
          bridge
        else
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
          easy = Curl::Easy.new
          easy.url = 'https://www.meethue.com/api/nupnp'
          easy.perform
          JSON(easy.body).each do |hash|
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
      bridge.lights
    end

    def add_lights
      bridge.add_lights
    end

    def light(id)
      id = id.to_s
      lights.select { |l| l.id == id }.first
    end

    def groups
      bridge.groups
    end

    def group(id = nil)
      return Group.new(self, bridge) if id.nil?

      id = id.to_s
      groups.select { |g| g.id == id }.first
    end

    def scenes
      bridge.scenes
    end

    def scene(id)
      id = id.to_s
      scenes.select { |s| s.id == id }.first
    end

  private

  def validate_user
    response = JSON(Net::HTTP.get(URI.parse("http://#{bridge.ip}/api/#{@username}")))

    if response.is_a? Array
      response = response.first
    end

    if error = response['error']
      raise get_error(error)
    end

    response['success']
  end

  def register_user
    body = JSON.dump({
      devicetype: 'Ruby',
      username: @username
    })

    uri = URI.parse("http://#{bridge.ip}/api")
    http = Net::HTTP.new(uri.host)
    response = JSON(http.request_post(uri.path, body).body).first

    if error = response['error']
      raise get_error(error)
    end

    response['success']
  end

  def get_error(error)
    # Find error class and return instance
    klass = Hue::ERROR_MAP[error['type']] || UnknownError unless klass
    klass.new(error['description'])
  end

  end
end

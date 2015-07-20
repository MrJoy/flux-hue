module Hue
  # Models an scene in the Hue system, providing means of
  # both reading and updating the state/configuration of the scene.
  class Scene
    include Enumerable
    include TranslateKeys

    # Unique identification number.
    attr_reader :id

    # The client object this scene is associated with.
    attr_reader :client

    # A unique, editable name given to the scene.
    attr_accessor :name

    # Whether or not the scene is active on a group.
    attr_reader :active

    def initialize(client:, id:, data: {})
      @client = client
      @id     = id

      unpack(data)
    end

    def lights; @lights ||= light_ids.map { |id| @client.light(id) }; end

  private

    attr_accessor :light_ids

    SCENE_KEYS_MAP = {
      name:       :name,
      light_ids:  :lights,
      active:     :active,
    }

    def unpack(data); unpack_hash(data, SCENE_KEYS_MAP); end

    def base_url; "#{client.url}/scenes/#{id}"; end
  end
end

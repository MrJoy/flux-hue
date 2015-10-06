SCREENS.draw do
  # This defines which Hue Bridge, and which group on that bridge a control
  # should affect.  It would be a bit nonsensical if this didn't correspond
  # to the arrangement of lights for the intensity controls though.
  STRAND_GROUPS = { strand1: { group1: ["Bridge-01", 0],
                               group2: ["Bridge-02", 0] },
                    strand2: { group1: ["Bridge-03", 0],
                               group2: ["Bridge-04", 0] } }
  screen("simulation", "launchpad") do
    # The desaturation controller.
    #
    # Transition time is how quickly to transition the saturation.  I suggest
    # not going too quickly because while the saturation is updated en masse
    # via group update, the brightness is done per-bulb in the main rendering
    # loop -- and you probably don't want to blind everyone during the
    # transition time.
    # Values are [saturation, maximum brightness] -- and nil means "don't
    # clamp brightness"
    SATURATION_POINTS = [[0.2, 0.00],
                         [0.6, 0.30],
                         [0.8, 0.70],
                         [1.0, nil]]
    SATURATION_TRANSITION = 1.0
    # ORBIT_POS = [[0, 4],
    #              [1, 4],
    #              [2, 4],
    #              [3, 4]]
    SATURATION_COLORS = { on:   0x1C103F,
                          off:  0x03030C,
                          down: 0x10103F }
    sat_size = SATURATION_POINTS.length
    [{ position: [4, 4], group: ["Bridge-01", "AccentAndMain"] },
     { position: [5, 4], group: ["Bridge-02", "AccentAndMain"] },
     { position: [6, 4], group: ["Bridge-03", "AccentAndMain"] },
     { position: [7, 4], group: ["Bridge-04", "AccentAndMain"] }]
      .each_with_index do |cfg, idx|
        vertical_slider("sat#{idx}", cfg[:position], sat_size, colors: SATURATION_COLORS,
                                                               default: sat_size - 1) do |val|
          # TODO: Delay the saturation update until the brightness has taken effect.
          ival, bri_max = SATURATION_POINTS[val]
          logger.info { "Saturation[#{idx},#{val}]: #{ival}" }
          NODES["SHIFTED_#{idx}"].clamp_to(bri_max)
          update_group!(cfg[:group], SATURATION_TRANSITION, "sat" => (255 * ival).round)
        end
      end

    # NOTE: Values are indexes into main_lights array.
    #
    # Excluding outermost lights because they extend beyond the seating area.
    # This configuration gives two rows, one corresponding to each of the two
    # light strands I'm putting up.
    #
    # TODO: Automatically suss out lights by using padding / widget size settings and spreading
    # TODO: across the simulations.
    SPOTLIGHT_POSITIONS = [[17, 18, 19, 20,   21, 22, 23, 24],
                           [ 3,  4,  5,  6,    7,  8,  9, 10]]
    w = SPOTLIGHT_POSITIONS[0].length
    h = SPOTLIGHT_POSITIONS.length
    radio_group("spotlighting", [0, 0], [w, h], colors:    { on:   0x032727,
                                                             off:  0x000202,
                                                             down: 0x103F3F },
                                                default:   nil,
                                                allow_off: true) do |val|
      val = SPOTLIGHT_POSITIONS.flatten[val] if val
      LOGGER.info { val ? "Spot ##{val}" : "Spot Off" }
      NODES["spotlighting"].spotlight!(val)
    end
  end

  screen("tuning", "launchpad") do
    # TODO: Controls for tuning white lights, accent lights, etc...
  end

  screen("tabset", "launchpad", default: true) do
    tab_set("screen_selector",
            default: 0,
            colors: { off:  :dark_gray,
                      down: :white,
                      on:   :light_gray }) do
      tab(:up,    screens["simulation"])
      tab(:down,  screens["tuning"])
      # tab(:left) do
      #   puts "PING!"
      # end
    end

    # Sometimes the process(es) on Hue Bridge that a thread is connected to
    # (or possibly `libcurl` on our end) just seem to get... stuck.  It's
    # very rare but it does happen.  Also, you may find heap growth to be an
    # issue, and swapping might cause you some problems.  This allows a quick
    # (under 0.5s last I measured) restart of the process.  It preserves state
    # to disk as it goes, so it will come back quickly and gracefully with no
    # more than a tiny hiccup in the simulation.
    #
    # Alternatively,  you may just want to do a quick reload after making a
    # configuration change.
    #
    # Position is which of the control buttons to use for this
    # kick-in-the-head function.
    # TODO: Make this optional.
    button("exit", :mixer, colors: { color: :dark_gray,
                                     down:  :white }) { kick! }
  end
end

SCREENS.screens["tabset"].start

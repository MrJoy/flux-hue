screens do
  screen("simulation", "launchpad") do
    [[4, 3],
     [5, 3],
     [6, 3],
     [7, 3]].each_with_index do |cfg, idx|
        vertical_slider("slider#{idx}", cfg, 5, colors:  { on:   0x1C103F,
                                                           off:  0x03030C,
                                                           down: 0x10103F },
                                                default: 3) do |val|
          LOGGER.info { "You pushed a thing: #{val.inspect}" }
        end
      end

    [[0, 4],
     [0, 5],
     [0, 6],
     [0, 7]].each_with_index do |cfg, idx|
        horizontal_slider("slider2#{idx}", cfg, 4, colors:  { on:   0x22003F,
                                                              off:  0x05000A,
                                                              down: 0x27103F },
                                                   default: slider2_size / 2) do |val|
          LOGGER.info { "You pushed a different thing: #{val.inspect}" }
        end
      end

    radio_group("spotlighting", [0, 0], [8, 2], colors:    { on:   0x032727,
                                                             off:  0x000202,
                                                             down: 0x103F3F },
                                                default:   nil,
                                                allow_off: true) do |val|
      LOGGER.info { val ? "Radio Group On #{val.inspect}" : "Radio Group Off" }
    end
  end

  screen("tuning", "launchpad") do
    vertical_slider("food_area", [0, 1], 7, colors:  { on:   :light_gray,
                                                       off:  :dark_gray,
                                                       down: :white },
                                            default: 3) do |val|
      LOGGER.info { "You pushed yet another thing: #{val.inspect}" }
    end
  end

  screen("tabset", "launchpad") do
    tab_set("screen_selector",
            colors: { off:  :dark_gray,
                      down: :white,
                      on:   :light_gray }) do
      tab(:up,    screens["simulation"])
      tab(:down,  screens["tuning"])
      tab(:left) do
        LOGGER.info { "PING!" }
      end
    end

    button("exit", :mixer, colors: { color: :dark_gray,
                                     down:  :white }) { SIM.kick! }
  end
end

screen("tabset").start

#!/usr/bin/env ruby

require_relative "./lib/flux_hue"
require_relative "./lib/widgets/on_only"

INTERACTION     = Launchpad::Interaction.new(use_threads: false)
BOARD           = []
PLAYER_COLORS   = [Color::LaunchPad::RED, Color::LaunchPad::BLUE].map(&:to_h)
current_player  = 0
(0..2).each do |x|
  BOARD[x] ||= []
  (0..2).each do |y|
    BOARD[x][y] = Widgets::OnOnly.new(launchpad: INTERACTION,
                                      x:    x,
                                      y:    y,
                                      off:  Color::LaunchPad::DARK_GRAY.to_h,
                                      on:   Color::LaunchPad::LIGHT_GRAY.to_h,
                                      down: Color::LaunchPad::WHITE.to_h,
                                      on_press: proc do |val|
                                        BOARD[x][y].on = PLAYER_COLORS[current_player]
                                        current_player += 1
                                        current_player = 0 if current_player > 1
                                        BOARD[x][y].render
                                      end)
  end
end

EXIT_BUTTON = Widgets::Button.new(launchpad: INTERACTION,
                                  position:  :mixer,
                                  color:     Color::LaunchPad::DARK_GRAY.to_h,
                                  down:      Color::LaunchPad::WHITE.to_h,
                                  on_press:  lambda do |value|
                                    return unless value != 0
                                    important "Ending simulation."
                                    INTERACTION.stop
                                  end)

def clear_board!
  BOARD.flatten.map(&:blank)
  sleep 0.01 # 88 updates/sec input limit!
  EXIT_BUTTON.blank
end

def main
  BOARD.flatten.map { |b| b.update(false) }
  EXIT_BUTTON.update(false)
  INTERACTION.start
end

main
clear_board!

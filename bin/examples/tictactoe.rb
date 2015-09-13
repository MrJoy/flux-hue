#!/usr/bin/env ruby

lib = File.expand_path("../../../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "sparkle_motion"
SparkleMotion.init!("tictactoe")
SparkleMotion.use_widgets!
SparkleMotion.use_launchpad!
require "sparkle_motion/launch_pad/widgets/on_only"

INTERACTION     = Launchpad::Interaction.new(use_threads: false)
BOARD           = []
PLAYER_COLORS   = [SparkleMotion::LaunchPad::Color::RED, SparkleMotion::LaunchPad::Color::BLUE]
                  .map(&:to_h)
COLORS          = SparkleMotion::LaunchPad::Color
LOGGER          = SparkleMotion.logger
cp              = 0
(0..2).each do |x|
  BOARD[x] ||= []
  (0..2).each do |y|
    BOARD[x][y] = SparkleMotion::LaunchPad::Widgets::OnOnly.new(launchpad: INTERACTION,
                                                                x:         x,
                                                                y:         y,
                                                                off:       COLORS::DARK_GRAY.to_h,
                                                                on:        COLORS::LIGHT_GRAY.to_h,
                                                                down:      COLORS::WHITE.to_h,
                                                                on_press:  proc do |_val|
                                                                  BOARD[x][y].on = PLAYER_COLORS[cp]
                                                                  cp            += 1
                                                                  cp             = 0 if cp > 1
                                                                  BOARD[x][y].render
                                                                end)
  end
end

EXIT_BUTTON = SparkleMotion::LaunchPad::Widgets::Button.new(launchpad: INTERACTION,
                                                            position:  :mixer,
                                                            color:     COLORS::DARK_GRAY.to_h,
                                                            down:      COLORS::WHITE.to_h,
                                                            on_press:  lambda do |value|
                                                              return unless value != 0
                                                              LOGGER.unknown { "Ending game." }
                                                              INTERACTION.stop
                                                            end)

RESET_BUTTON = SparkleMotion::LaunchPad::Widgets::Button.new(launchpad: INTERACTION,
                                                             position:  :session,
                                                             color:     COLORS::DARK_GREEN.to_h,
                                                             down:      COLORS::WHITE.to_h,
                                                             on_press:  lambda do |value|
                                                               return unless value != 0
                                                               init_board!
                                                             end)

def init_board!
  BOARD.flatten.map { |b| b.update(false) }
  EXIT_BUTTON.update(false)
  RESET_BUTTON.update(false)
end

def clear_board!
  BOARD.flatten.map(&:blank)
  sleep 0.01 # 88 updates/sec input limit!
  EXIT_BUTTON.blank
  RESET_BUTTON.blank
end

def main
  init_board!
  INTERACTION.start
  clear_board!
end

main

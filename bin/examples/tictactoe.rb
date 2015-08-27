#!/usr/bin/env ruby

lib = File.expand_path("../../../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "sparkle_motion"
FluxHue.init!("tictactoe")
FluxHue.use_widgets!
FluxHue.use_launchpad!

INTERACTION     = Launchpad::Interaction.new(use_threads: false)
BOARD           = []
PLAYER_COLORS   = [SparkleMotion::LaunchPad::Color::RED, SparkleMotion::LaunchPad::Color::BLUE].map(&:to_h)
current_player  = 0
(0..2).each do |x|
  BOARD[x] ||= []
  (0..2).each do |y|
    BOARD[x][y] = SparkleMotion::LaunchPad::Widgets::OnOnly.new(launchpad: INTERACTION,
                                                                x:         x,
                                                                y:         y,
                                                                off:       SparkleMotion::LaunchPad::Color::DARK_GRAY.to_h,
                                                                on:        SparkleMotion::LaunchPad::Color::LIGHT_GRAY.to_h,
                                                                down:      SparkleMotion::LaunchPad::Color::WHITE.to_h,
                                                                on_press:  proc do |_val|
                                                                  BOARD[x][y].on = PLAYER_COLORS[current_player]
                                                                  current_player += 1
                                                                  current_player = 0 if current_player > 1
                                                                  BOARD[x][y].render
                                                                end)
  end
end

EXIT_BUTTON = SparkleMotion::LaunchPad::Widgets::Button.new(launchpad: INTERACTION,
                                                            position:  :mixer,
                                                            color:     SparkleMotion::LaunchPad::Color::DARK_GRAY.to_h,
                                                            down:      SparkleMotion::LaunchPad::Color::WHITE.to_h,
                                                            on_press:  lambda do |value|
                                                              return unless value != 0
                                                              FluxHue.logger.unknown { "Ending simulation." }
                                                              INTERACTION.stop
                                                            end)

RESET_BUTTON = SparkleMotion::LaunchPad::Widgets::Button.new(launchpad: INTERACTION,
                                                             position:  :session,
                                                             color:     SparkleMotion::LaunchPad::Color::DARK_GREEN.to_h,
                                                             down:      SparkleMotion::LaunchPad::Color::WHITE.to_h,
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

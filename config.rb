# TODO: Connect-4 clone.
# TODO: Checkers clone.
# TODO: AI for tic-tac-toe.

# TODO: Count all diagonals.
# TODO: Require contiguous lines!

class TicTacToe
  OPEN_POSITION = { on: :dark_gray, off: :dark_gray, down: :white }

  PLAYERS = [{ on: :red,  off: :red,  down: :light_red },
             { on: :blue, off: :blue, down: :light_blue }]

  BOARD_SIZE = 3
  WIN_LENGTH = 3

  attr_accessor :grid
  attr_accessor :current_player

  def initialize
    @max_coord = BOARD_SIZE - 1
    @gameover = false
    @buttons  = (0..@max_coord).map { |_| (0..@max_coord).map { |_| nil } }
    reset!
  end

  def positions
    @positions ||= begin
      tmp = []
      (0..@max_coord).each do |x|
        (0..@max_coord).each do |y|
          tmp << [x, y]
        end
      end
      tmp
    end
  end

  def button_at(coord, widget)
    @buttons[coord[0]][coord[1]] = widget
  end

  def reset!
    @grid           = (0..@max_coord).map { |_| (0..@max_coord).map { |_| nil } }
    @current_player = 0

    @buttons.flatten.map do |widget|
      next unless widget
      widget.apply_colors!(OPEN_POSITION)
      widget.render
    end
    @gameover = false
  end

  def handle_winner_in_line!(line, msg)
    winner =  line
              .group_by { |val| val }
              .select { |_k, v| v.length == WIN_LENGTH }
              .values
              .flatten
              .first
    return unless winner
    puts "Winner at #{msg}: player ##{winner + 1}"
    @gameover = true
  end

  def detect_end_of_game!
    return if @gameover
    # TODO: Clean this the fuck up.

    # Column-wise, row-wise, diagonals:
    lines = @grid +
            (0..@max_coord).map { |row| @grid.map { |col| col[row] } } +
            [(0..@max_coord).map { |x| @grid[x][x] },
             (0..@max_coord).map { |x| @grid[x][@max_coord - x] }]

    lines.each_with_index do |col, idx|
      handle_winner_in_line!(col, "line ##{idx}")
    end
  end

  def play_position(coord)
    x, y = *coord
    return if @gameover
    return unless @grid[x][y].nil?

    @grid[x][y]       = @current_player
    target_color      = PLAYERS[@current_player]
    @current_player  += 1
    @current_player   = 0 if @current_player > 1

    return unless @buttons[x][y]
    @buttons[x][y].apply_colors!(target_color)
  end
end

STATE = TicTacToe.new

screens do
  screen("tictactoe", "launchpad") do
    STATE.positions.each do |coord|
      widget = button("board_#{coord[0]}_#{coord[1]}", coord, colors: TicTacToe::OPEN_POSITION) do
        STATE.play_position(coord)
        STATE.detect_end_of_game!
      end
      STATE.button_at(coord, widget)
    end

    button("exit", :mixer, colors: { on: :dark_red, off: :dark_red, down: :red }) do
      SIM.exit
    end

    button("new_game", :session, colors: { on: :dark_green, off: :dark_green, down: :green }) do
      STATE.reset!
    end
  end
end

# TODO: End-of-game detection.
# TODO: Score-keeping.
# TODO: Cleaner code structure.

screen("tictactoe").start

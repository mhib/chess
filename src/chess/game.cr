require "./position"
require "./move_wrapper"

class Chess::Game
  class NoMovesException < Exception
  end
  class InvalidMoveException < Exception
  end
  @position_stack : Array(Position)
  @position_counter : Hash(Position, Int32)

  def initialize
    @position_stack = [Position::INITIAL]
    @position_counter = {
      Position::INITIAL => 1
    }
  end

  def initialize(fen : String)
    position = Position.new(fen)
    @position_stack = [position]
    @position_counter = {
      position => 1
    }
  end

  def initialize(position : Position)
    @position_stack = [position]
    @position_counter = {
      position => 1
    }
  end

  def make_move!(string)
    move = current_position.generate_wrapped_moves.find { |move| move.to_s == string }
    if move.nil?
      raise InvalidMoveException.new "Invalid move"
    end
    new_position = current_position.make_legal_move(move)
    @position_stack << new_position
    @position_counter[new_position] = @position_counter.fetch(new_position, 0) + 1
    self
  end

  def possible_moves
    current_position.generate_wrapped_moves.map(&.to_s)
  end

  def undo_last_move!
    last_position = @position_stack.pop
    @position_counter[last_position] -= 1
    @position_counter.delete(last_position) if @position_counter[last_position] == 0
  end

  def current_position : Position
    @position_stack.last
  end

  def over?
    draw? || black_won? || white_won?
  end

  def black_won?
    current_position.side_to_move.white? && current_position.is_in_check? && current_position.generate_moves.empty?
  end

  def white_won?
    current_position.side_to_move.black? && current_position.is_in_check? && current_position.generate_moves.empty?
  end

  def draw?
    current_position.fifty_move > 100 ||
      current_position.insufficient_material? ||
      (!current_position.is_in_check? && current_position.generate_moves.empty?) ||
      (@position_counter.each_value.any? { |value| value >= 3 })
  end

  def positions
    @position_stack.map(&.to_fen)
  end

  def move_count
    @position_stack.size - 1
  end

  def moves
    (1...@position_stack.size).map do |idx|
      MoveWrapper.new(@position_stack[idx].last_move).to_s
    end
  end
end

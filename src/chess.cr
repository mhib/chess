require "./chess/bitboard"
require "./chess/position"
require "./chess/game"

module Chess
  VERSION = "0.1.0"

  def self.perft(position, depth)
    return 1 if depth == 0
    counter = 0
    position.generate_pseudolegal_moves.each do |move|
      if (child = position.make_move(move.to_i32))
        counter += self.perft(child, depth - 1)
      end
    end
    counter
  end
end


require "../src/chess"

game = Chess::Game.new

while !game.over?
  game.make_move!(game.possible_moves.sample)
end

puts game.positions
puts game.moves

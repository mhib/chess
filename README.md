# chess
A chess library for crystal with [Plain Magic Bitboard](https://www.chessprogramming.org/Magic_Bitboards#Plain) move generation

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     chess:
       github: mhib/chess
   ```

2. Run `shards install`

## Usage

```crystal
require "chess"

game = Chess::Game.new

while !game.over?
  game.make_move!(game.possible_moves.sample)
end

puts game.positions
puts game.moves
```

## Performance

Around 30 times slower than Stockfish 7 using Intel® Core™ i5-8250U

### Chess

Code:
```crystal
require "./src/chess.cr"

start = Time.monotonic
result = Chess.perft(Chess::Position::INITIAL, 6)
puts Time.monotonic - start
puts result
```
Built with `--release` flag
```
➜ ./bench
00:00:18.992260813
119060324
```


### Stockfish 7
```
Stockfish 7 64 by T. Romstad, M. Costalba, J. Kiiski, G. Linscott
position startpos
perft 6

Position: 1/1
a2a3: 4463267
b2b3: 5310358
c2c3: 5417640
d2d3: 8073082
e2e3: 9726018
f2f3: 4404141
g2g3: 5346260
h2h3: 4463070
a2a4: 5363555
b2b4: 5293555
c2c4: 5866666
d2d4: 8879566
e2e4: 9771632
f2f4: 4890429
g2g4: 5239875
h2h4: 5385554
b1a3: 4856835
b1c3: 5708064
g1f3: 5723523
g1h3: 4877234

===========================
Total time (ms) : 623
Nodes searched  : 119060324
Nodes/second    : 191108064
```

## Todo
- [ ] PGN handling
- [ ] Documentation

## Contributing

1. Fork it (<https://github.com/mhib/chess/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Marcin Henryk Bartkowiak](https://github.com/your-github-user) - creator and maintainer

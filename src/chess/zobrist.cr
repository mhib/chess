require "./position"
require "./square"
require "./piece"
require "./colour"

struct Chess::Zobrist
  INSTANCE = new

  getter colour_position, ep_square, flags, colour

  @colour_position : Array(Array(Array(UInt64)))
  @ep_square : Array(UInt64)
  @flags : Array(UInt64)
  @colour : UInt64

  def initialize
    r = Random.new
    @colour_position = Array.new(Colour::White.value + 1) do |y|
      Array.new(Piece::King.value + 1) do |x|
        Array.new(64) { r.rand(UInt64::MAX) }
      end
    end
    @ep_square = Array.new(65) do |idx|
      r.rand(UInt64::MAX)
    end
    @ep_square[Square::NoSquare.value] = 0u64
    @flags = Array.new(16) { r.rand(UInt64::MAX) }
    @colour = r.rand(UInt64::MAX)
  end

  def self.instance
    INSTANCE
  end
end

require "./piece"

# Move is represented as int32
# Bits are:
# 4 bits for move type
# 3 bits for captured piece type
# 3 bits for piece type
# 6 bits to
# 6 bits from

module Chess::Move
  extend self

  QuietMove              =  0
  Capture                =  1
  DoublePawnPush         =  8
  KingCastle             =  4
  QueenCastle            = 12
  EPCapture              =  9
  KnightPromotion        =  2
  BishopPromotion        =  6
  RookPromotion          = 10
  QueenPromotion         = 14
  KnightCapturePromotion =  3
  BishopCapturePromotion =  7
  RookCapturePromotion   = 11
  QueenCapturePromotion  = 15

  NullMove = 0

  WhiteKingSideCastle  = new_move(Square::E1, Square::G1, Piece::King, Piece::None, KingCastle)
  WhiteQueenSideCastle = new_move(Square::E1, Square::C1, Piece::King, Piece::None, QueenCastle)
  BlackKingSideCastle  = new_move(Square::E8, Square::G8, Piece::King, Piece::None, KingCastle)
  BlackQueenSideCastle = new_move(Square::E8, Square::C8, Piece::King, Piece::None, QueenCastle)

  def from(m)
    Square.new(m & 0x3f)
  end

  def to(m)
    Square.new((m >> 6) & 0x3f)
  end

  def is_capture?(m)
    m & (1 << 18) != 0
  end

  def moved_piece(m)
    Piece.new((m >> 12) & 0x7)
  end

  def captured_piece(m)
    Piece.new((m >> 15) & 0x7)
  end

  def type(m)
    m >> 18
  end

  def special(m)
    m >> 20
  end

  def is_promotion?(m)
    m & (1 << 19) != 0
  end

  def is_capture_or_promotion?(m)
    m & ((1 << 19) | (1 << 18)) != 0
  end

  def is_castling?(m)
    t = type(m)
    t & 3 == 0 && t & (1 << 2) != 0
  end

  def promoted_piece(m)
    Piece.new(Piece::Knight.value + (m >> 20))
  end

  # Either quiete move or capture
  def is_normal?(m)
    m >> 18 < 2
  end

  def new_move(from : Number, to : Number, piece_type, captured_type, move_type) : Int32
    from.to_i32 | (to << 6) | (piece_type.value << 12) | (captured_type.value << 15) | (move_type << 18)
  end

  def new_move(from : Square, to : Square, piece_type, captured_type, move_type) : Int32
    from.value.to_i32 | (to.value << 6) | (piece_type.value << 12) | (captured_type.value << 15) | (move_type << 18)
  end

  def new_type(capture, promotion, s1, s0)
    capture | (promotion << 1) | (s1 << 2) | (s0 << 3)
  end
end

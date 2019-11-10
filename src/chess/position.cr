require "./bitboard"
require "./zobrist"
require "./square"
require "./piece"
require "./colour"
require "./move_generator"
require "./move_wrapper"

struct Chess::Position
  WHITE_KING_SIDE_CASTLE_FLAG  = 1u8
  WHITE_QUEEN_SIDE_CASTLE_FLAG = 1u8 << 1
  BLACK_KING_SIDE_CASTLE_FLAG  = 1u8 << 2
  BLACK_QUEEN_SIDE_CASTLE_FLAG = 1u8 << 3

  KING_CASTLE_FLAGS = [
    BLACK_QUEEN_SIDE_CASTLE_FLAG | BLACK_KING_SIDE_CASTLE_FLAG,
    WHITE_QUEEN_SIDE_CASTLE_FLAG | WHITE_KING_SIDE_CASTLE_FLAG,
  ]

  ROOK_CASTLE_FLAGS = Array(UInt8).new(64) do |idx|
    case idx
    when Square::A1.value
      WHITE_QUEEN_SIDE_CASTLE_FLAG
    when Square::H1.value
      WHITE_KING_SIDE_CASTLE_FLAG
    when Square::A8.value
      BLACK_QUEEN_SIDE_CASTLE_FLAG
    when Square::H8.value
      BLACK_KING_SIDE_CASTLE_FLAG
    else
      0u8
    end
  end

  property colours, pieces, key, pawn_key, side_to_move, ep_square, fifty_move, last_move, flags, move_count

  INITIAL_POSITION_IN_FEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

  INITIAL = new(INITIAL_POSITION_IN_FEN)

  def initialize
    @colours = Array(UInt64).new(Colour::White.value + 1, 0u64)
    @pieces = Array(UInt64).new(Piece::King.value + 1, 0u64)
    @key = 0u64
    @pawn_key = 0u64
    @side_to_move = Colour::White
    @ep_square = Square::NoSquare
    @fifty_move = 0
    @flags = 0u8
    @side_to_move = Colour::White
    @last_move = Move::NullMove
    @move_count = 0
  end

  def initialize(fen)
    @colours = Array(UInt64).new(Colour::White.value + 1, 0u64)
    @pieces = Array(UInt64).new(Piece::King.value + 1, 0u64)
    @key = 0u64
    @pawn_key = 0u64
    @side_to_move = Colour::White
    @ep_square = Square::NoSquare
    @fifty_move = 0
    @flags = WHITE_KING_SIDE_CASTLE_FLAG | WHITE_QUEEN_SIDE_CASTLE_FLAG | BLACK_KING_SIDE_CASTLE_FLAG | BLACK_QUEEN_SIDE_CASTLE_FLAG
    @last_move = Move::NullMove
    @move_count = 0

    slices = fen.split(" ")
    y = 7
    x = 0
    slices[0].each_char do |char|
      if char == '/'
        y -= 1
        x = 0
      elsif char.ascii_number?
        x += char.to_i
      else
        insert_piece(char, Bitboard.square_bb(y * 8 + x))
        x += 1
      end
    end

    @side_to_move = Colour.new((slices[1] == "w").to_unsafe)

    slices[2].each_char do |char|
      case char
      when 'K'
        @flags ^= WHITE_KING_SIDE_CASTLE_FLAG
      when 'Q'
        @flags ^= WHITE_QUEEN_SIDE_CASTLE_FLAG
      when 'k'
        @flags ^= BLACK_KING_SIDE_CASTLE_FLAG
      when 'q'
        @flags ^= BLACK_QUEEN_SIDE_CASTLE_FLAG
      end
    end

    if slices[3] != "-"
      @ep_square = Square.new(slices[3][0].ord - 'a'.ord + (slices[3][1].ord - '1'.ord) * 8)
    end

    if slices.size >= 5
      @fifty_move = slices[4].to_i
    end

    if slices.size >= 6
      @move_count = slices[5].to_i
    end

    hash!
  end

  PIECE_CHARS = "pnbrqk."
  def to_fen
    pieces_string = String::Builder.new
    all_occupation = colours[Colour::White.value] | colours[Colour::Black.value]
    Rank.values.reverse_each do |rank|
      empty_counter = 0
      (rank.value * 8).upto(rank.value * 8 + 7) do |idx|
        if type_on_square(idx).none?
          empty_counter += 1
        else
          pieces_string << empty_counter.to_s if empty_counter != 0
          empty_counter = 0

          char = PIECE_CHARS[type_on_square(idx).value]
          char = char.upcase if Bitboard.square_bb(idx) & whites != 0
          pieces_string << char
        end
      end
      pieces_string << empty_counter.to_s if empty_counter != 0

      if rank != Rank::RANK_1
        pieces_string << "/"
      end
    end

    flag_string = ""
    flag_string += "K" if flags & WHITE_KING_SIDE_CASTLE_FLAG == 0
    flag_string += "Q" if flags & WHITE_QUEEN_SIDE_CASTLE_FLAG == 0
    flag_string += "k" if flags & BLACK_KING_SIDE_CASTLE_FLAG == 0
    flag_string += "q" if flags & BLACK_QUEEN_SIDE_CASTLE_FLAG == 0
    flag_string = "-" if flag_string == ""

    side_to_move_string = side_to_move.white? ? "w" : "b"
    ep_square_string = ep_square == Square::NoSquare ? "-" : Bitboard.square_string(ep_square)

    "#{pieces_string.to_s} #{side_to_move_string} #{flag_string} #{ep_square_string} #{fifty_move} #{move_count}"
  end

  def insufficient_material?
    (pieces[Piece::Pawn.value] | pieces[Piece::Rook.value] | pieces[Piece::Queen.value]) == 0 &&
      !Bitboard.more_than_one?(colours[Colour::White.value]) && !Bitboard.more_than_one?(colours[Colour::Black.value]) &&
      (
       !Bitboard.more_than_one?(pieces[Piece::Knight.value] | pieces[Piece::Bishop.value]) ||
       (pieces[Piece::Bishop.value] != 0 && pieces[Piece::Knight.value].popcount <= 2)
      )
  end

  def type_on_square(idx)
    square_bb = Bitboard.square_bb(idx)
    if square_bb & pieces[Piece::Pawn.value] != 0
      Piece::Pawn
    elsif square_bb & pieces[Piece::Knight.value] != 0
      Piece::Knight
    elsif square_bb & pieces[Piece::Bishop.value] != 0
      Piece::Bishop
    elsif square_bb & pieces[Piece::Rook.value] != 0
      Piece::Rook
    elsif square_bb & pieces[Piece::Queen.value] != 0
      Piece::Queen
    elsif square_bb & pieces[Piece::King.value] != 0
      Piece::King
    else
      Piece::None
    end
  end

  def is_square_attacked?(square, colour)
    their_occupation = colours[colour.value]

    return Bitboard.pawn_attacks(colour.flip, square) & their_occupation & pieces[Piece::Pawn.value] != 0 ||
      Bitboard.knight_attacks(square) & their_occupation & pieces[Piece::Knight.value] != 0 ||
      Bitboard.king_attacks(square) & pieces[Piece::King.value] & their_occupation != 0 ||
      Bitboard.bishop_attacks(square, colours[Colour::Black.value] | colours[Colour::White.value]) & (pieces[Piece::Bishop.value] | pieces[Piece::Queen.value]) & their_occupation != 0 ||
      Bitboard.rook_attacks(square, colours[Colour::Black.value] | colours[Colour::White.value]) & (pieces[Piece::Queen.value] | pieces[Piece::Rook.value]) & their_occupation != 0
  end

  def pretty
    sb = String::Builder.new
    7.step(to: 0, by: -1) do |y|
      0.upto(7) do |x|
        char = PIECE_CHARS[type_on_square(y * 8 + x).value]
        if colours[Colour::White.value] & Bitboard.square_bb(y * 8 + x) != 0
          char = char.upcase
        end
        sb << char
      end
      sb << "\n"
    end
    sb.to_s
  end

  def generate_pseudolegal_moves
    MoveGenerator::AllGenerator.new(self)
  end

  def generate_moves
    MoveGenerator::AllGenerator.new(self)
      .reject { |move| make_move(move).nil? }
  end

  def generate_wrapped_moves
    generate_moves.map { |move| MoveWrapper.new(move) }
  end

  EP_SQUARE_DIRECTION = [8, -8]
  def make_legal_move(move : MoveWrapper)
    make_legal_move(move.move)
  end

  # Same as make_move but without legality check
  def make_legal_move(move : Int32) : Position
    zobrist = Zobrist.instance
    res = self.class.new

    res.colours[Colour::Black.value] = colours[Colour::Black.value]
    res.colours[Colour::White.value] = colours[Colour::White.value]
    res.pieces[Piece::Pawn.value] = pieces[Piece::Pawn.value]
    res.pieces[Piece::Knight.value] = pieces[Piece::Knight.value]
    res.pieces[Piece::Bishop.value] = pieces[Piece::Bishop.value]
    res.pieces[Piece::Rook.value] = pieces[Piece::Rook.value]
    res.pieces[Piece::Queen.value] = pieces[Piece::Queen.value]
    res.pieces[Piece::King.value] = pieces[Piece::King.value]
    res.side_to_move = side_to_move
    res.flags = flags
    res.key = key ^ zobrist.colour ^ zobrist.ep_square[ep_square.value] ^ zobrist.flags[flags]
    res.pawn_key = pawn_key ^ zobrist.colour

    if Move.moved_piece(move).pawn? || Move.is_capture?(move)
      res.fifty_move = 0
    else
      res.fifty_move = fifty_move + 1
    end

    res.ep_square = Square::NoSquare

    if !Move.is_promotion?(move)
      res.move_piece!(Move.moved_piece(move), side_to_move, Move.from(move), Move.to(move))
      case Move.type(move)
      when Move::DoublePawnPush
        res.ep_square = Move.to(move) + EP_SQUARE_DIRECTION[side_to_move.value]
        res.key ^= zobrist.ep_square[Move.to(move).value + EP_SQUARE_DIRECTION[side_to_move.value]]
      when Move::Capture
        res.toggle_piece!(Move.captured_piece(move), Colour.new(side_to_move.value ^ 1), Move.to(move))
      when Move::KingCastle
        if side_to_move == Colour::White
          res.move_piece!(Piece::Rook, Colour::White, Square::H1, Square::F1)
        else
          res.move_piece!(Piece::Rook, Colour::Black, Square::H8, Square::F8)
        end
      when Move::QueenCastle
        if side_to_move == Colour::White
          res.move_piece!(Piece::Rook, Colour::White, Square::A1, Square::D1)
        else
          res.move_piece!(Piece::Rook, Colour::Black, Square::A8, Square::D8)
        end
      when Move::EPCapture
        res.toggle_piece!(Piece::Pawn, side_to_move.flip, Square.new(Move.to(move).value - EP_SQUARE_DIRECTION[side_to_move.flip.value]))
      end
    else
      res.toggle_piece!(Piece::Pawn, side_to_move, Move.from(move))
      res.toggle_piece!(Move.promoted_piece(move), side_to_move, Move.to(move))
      if Move.is_capture?(move)
        res.toggle_piece!(Move.captured_piece(move), Colour.new(side_to_move.value ^ 1), Move.to(move))
      end
    end

    res.key ^= zobrist.flags[res.flags]
    res.side_to_move = side_to_move.flip
    res.last_move = move
    res.move_count = side_to_move.black? ? move_count + 1 : move_count

    res
  end

  def make_move(move : MoveWrapper)
    make_move(move.move)
  end

  def make_move(move : Int32) : (Position | Nil)
    zobrist = Zobrist.instance
    res = self.class.new

    res.colours[Colour::Black.value] = colours[Colour::Black.value]
    res.colours[Colour::White.value] = colours[Colour::White.value]
    res.pieces[Piece::Pawn.value] = pieces[Piece::Pawn.value]
    res.pieces[Piece::Knight.value] = pieces[Piece::Knight.value]
    res.pieces[Piece::Bishop.value] = pieces[Piece::Bishop.value]
    res.pieces[Piece::Rook.value] = pieces[Piece::Rook.value]
    res.pieces[Piece::Queen.value] = pieces[Piece::Queen.value]
    res.pieces[Piece::King.value] = pieces[Piece::King.value]
    res.side_to_move = side_to_move
    res.flags = flags
    res.key = key ^ zobrist.colour ^ zobrist.ep_square[ep_square.value] ^ zobrist.flags[flags]
    res.pawn_key = pawn_key ^ zobrist.colour

    if Move.moved_piece(move).pawn? || Move.is_capture?(move)
      res.fifty_move = 0
    else
      res.fifty_move = fifty_move + 1
    end

    res.ep_square = Square::NoSquare

    if !Move.is_promotion?(move)
      res.move_piece!(Move.moved_piece(move), side_to_move, Move.from(move), Move.to(move))
      case Move.type(move)
      when Move::DoublePawnPush
        res.ep_square = Move.to(move) + EP_SQUARE_DIRECTION[side_to_move.value]
        res.key ^= zobrist.ep_square[Move.to(move).value + EP_SQUARE_DIRECTION[side_to_move.value]]
      when Move::Capture
        res.toggle_piece!(Move.captured_piece(move), Colour.new(side_to_move.value ^ 1), Move.to(move))
      when Move::KingCastle
        if side_to_move == Colour::White
          res.move_piece!(Piece::Rook, Colour::White, Square::H1, Square::F1)
        else
          res.move_piece!(Piece::Rook, Colour::Black, Square::H8, Square::F8)
        end
      when Move::QueenCastle
        if side_to_move == Colour::White
          res.move_piece!(Piece::Rook, Colour::White, Square::A1, Square::D1)
        else
          res.move_piece!(Piece::Rook, Colour::Black, Square::A8, Square::D8)
        end
      when Move::EPCapture
        res.toggle_piece!(Piece::Pawn, side_to_move.flip, Square.new(Move.to(move).value - EP_SQUARE_DIRECTION[side_to_move.flip.value]))
      end
    else
      res.toggle_piece!(Piece::Pawn, side_to_move, Move.from(move))
      res.toggle_piece!(Move.promoted_piece(move), side_to_move, Move.to(move))
      if Move.is_capture?(move)
        res.toggle_piece!(Move.captured_piece(move), Colour.new(side_to_move.value ^ 1), Move.to(move))
      end
    end

    if res.is_in_check?
      return nil
    end

    res.key ^= zobrist.flags[res.flags]
    res.side_to_move = side_to_move.flip
    res.last_move = move
    res.move_count = side_to_move.black? ? move_count + 1 : move_count

    res
  end

  def is_in_check?
    is_square_attacked?(Square.new((colours[side_to_move.value] & pieces[Piece::King.value]).trailing_zeros_count.to_i32), Colour.new(side_to_move.value ^ 1))
  end

  def whites
    colours[Colour::White.value]
  end

  def blacks
    colours[Colour::White.value]
  end

  {%for piece in %w[pawn knight bishop rook queen king] %}
    def {{piece.id}}s
      pieces[Piece::{{piece.id.capitalize}}.value]
    end
  {% end %}

  def blacks
    colours[Colour::White.value]
  end

  protected def toggle_piece!(piece, side, square)
    b = Bitboard.square_bb(square.value)
    colours[side.value] ^= b
    pieces[piece.value] ^= b
    @key ^= Zobrist.instance.colour_position[side.value][piece.value][square.value]
    case piece
    when Piece::Pawn
      @pawn_key ^= Zobrist.instance.colour_position[side.value][piece.value][square.value]
    when Piece::Rook
      @flags |= ROOK_CASTLE_FLAGS[square.value]
    end
  end

  protected def move_piece!(piece, side, from, to)
    b = Bitboard.square_bb(from.value) | Bitboard.square_bb(to.value)
    colours[side.value] ^= b
    pieces[piece.value] ^= b
    @key ^=
      Zobrist.instance.colour_position[side_to_move.value][piece.value][from.value] ^
        Zobrist.instance.colour_position[side_to_move.value][piece.value][to.value]
    case piece
    when Piece::King
      @flags |= KING_CASTLE_FLAGS[side_to_move.value]
      @pawn_key ^= Zobrist.instance.colour_position[side_to_move.value][piece.value][from.value] ^
                   Zobrist.instance.colour_position[side_to_move.value][piece.value][to.value]
    when Piece::Pawn
      @pawn_key ^= Zobrist.instance.colour_position[side_to_move.value][piece.value][to.value] ^
                   Zobrist.instance.colour_position[side_to_move.value][piece.value][from.value]
    when Piece::Rook
      @flags |= ROOK_CASTLE_FLAGS[from.value]
    end
  end

  private def insert_piece(piece, bit)
    @colours[piece.uppercase?.to_unsafe] |= bit
    case piece.downcase
    when 'p'
      @pieces[Piece::Pawn.value] |= bit
    when 'r'
      @pieces[Piece::Rook.value] |= bit
    when 'n'
      @pieces[Piece::Knight.value] |= bit
    when 'b'
      @pieces[Piece::Bishop.value] |= bit
    when 'q'
      @pieces[Piece::Queen.value] |= bit
    when 'k'
      @pieces[Piece::King.value] |= bit
    end
  end

  private def hash!
    zobrist = Zobrist.instance
    Piece.each do |piece|
      break if piece == Piece::None
      Colour.each do |colour|
        fromBB = @pieces[piece.value] & @colours[colour.value]
        while fromBB != 0
          fromId = fromBB.trailing_zeros_count

          @key ^= zobrist.colour_position[colour.value][piece.value][fromId]
          if piece == Piece::Pawn || piece == Piece::King
            @pawn_key ^= zobrist.colour_position[colour.value][piece.value][fromId]
          end
          fromBB &= fromBB - 1
        end
      end
    end
    @key ^= zobrist.flags[@flags]
    @key &= zobrist.ep_square[@ep_square.value]
    if @side_to_move == Colour::White
      @key ^= zobrist.colour
      @pawn_key ^= zobrist.colour
    end
  end
end

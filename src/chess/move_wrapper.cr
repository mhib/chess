require "./move"
require "./bitboard"

struct Chess::MoveWrapper
  getter move

  def initialize(@move : Int32)
  end

  {% for method in %w[from to captured_piece type special is_promotion? is_capture_or_promotion? is_castling? promoted_piece] %}
    def {{method.id}}
      Move.{{method.id}}(@move)
    end
  {% end %}

  def to_s
    promo = ""
    if is_promotion?
      promo = "nbrq"[special]
    end
    Bitboard.square_string(from) + Bitboard.square_string(to) + promo
  end
end

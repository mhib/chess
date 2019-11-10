require "./position"
require "./rank"
require "./colour"
require "./move"
require "./piece"
require "./bitboard"

module Chess::MoveGenerator
  struct AllGenerator
    include Enumerable(Int32)

    getter position

    def initialize(@position : Position)
    end

    def each
      our_occupation = position.colours[position.side_to_move.value]
      their_occupation = position.colours[position.side_to_move.flip.value]
      all_occupation = our_occupation | their_occupation

      if position.side_to_move == Colour::White
        from_bb = position.pieces[Piece::Pawn.value] & position.colours[Colour::White.value]
        while from_bb > 0
          from_id = from_bb.trailing_zeros_count
          from_mask = Bitboard.square_bb(from_id)
          from_rank = Bitboard.rank(from_id)
          if from_rank == Rank::RANK_7.value
            to_mask = from_mask << 8
            if all_occupation & to_mask == 0
              yield Move.new_move(from_id, from_id + 8, Piece::Pawn, Piece::None, Move.new_type(0, 1, 1, 1))
              yield Move.new_move(from_id, from_id + 8, Piece::Pawn, Piece::None, Move.new_type(0, 1, 0, 1))
              yield Move.new_move(from_id, from_id + 8, Piece::Pawn, Piece::None, Move.new_type(0, 1, 1, 0))
              yield Move.new_move(from_id, from_id + 8, Piece::Pawn, Piece::None, Move.new_type(0, 1, 0, 0))
            end
            to_bb = Bitboard.pawn_attacks(Colour::White, from_id) & position.colours[Colour::Black.value]
            while to_bb > 0
              to_id = to_bb.trailing_zeros_count
              capture_type = position.type_on_square(to_id)
              yield Move.new_move(from_id, to_id, Piece::Pawn, capture_type, Move.new_type(1, 1, 1, 1))
              yield Move.new_move(from_id, to_id, Piece::Pawn, capture_type, Move.new_type(1, 1, 0, 1))
              yield Move.new_move(from_id, to_id, Piece::Pawn, capture_type, Move.new_type(1, 1, 1, 0))
              yield Move.new_move(from_id, to_id, Piece::Pawn, capture_type, Move.new_type(1, 1, 0, 0))
              to_bb &= (to_bb - 1)
            end
          else
            to_id = from_id + 8
            to_mask = Bitboard.square_bb(to_id)
            if all_occupation & to_mask == 0
              yield Move.new_move(from_id, to_id, Piece::Pawn, Piece::None, 0)
              # Double pawn push
              to_id = from_id + 16
              to_mask = Bitboard.square_bb(to_id)
              if from_rank == Rank::RANK_2.value != 0 && all_occupation & to_mask == 0
                yield Move.new_move(from_id, to_id, Piece::Pawn, Piece::None, Move.new_type(0, 0, 0, 1))
              end
            end
            to_bb = Bitboard.pawn_attacks(Colour::White, from_id) & position.colours[Colour::Black.value]
            while to_bb > 0
              to_id = to_bb.trailing_zeros_count
              to_mask = Bitboard.square_bb(to_id)
              yield Move.new_move(from_id, to_id, Piece::Pawn, position.type_on_square(to_id), Move.new_type(1, 0, 0, 0))
              to_bb &= (to_bb - 1)
            end
          end
          from_bb &= (from_bb - 1)
        end
        if position.ep_square != Square::NoSquare
          ep_bb = (Bitboard.square_bb(position.ep_square.value - 9) | Bitboard.square_bb(position.ep_square.value - 7)) & Bitboard::RANK_5_BB
          from_bb = ep_bb & position.pieces[Piece::Pawn.value] & position.colours[Colour::White.value]
          while from_bb > 0
            from_id = from_bb.trailing_zeros_count
            yield Move.new_move(from_id, position.ep_square.value, Piece::Pawn, Piece::Pawn, Move.new_type(1, 0, 0, 1))
            from_bb &= (from_bb - 1)
          end
        end

        # Castling
        if all_occupation & Bitboard::WHITE_KING_CASTLE_BLOCK_BB == 0 && position.flags & Position::WHITE_KING_SIDE_CASTLE_FLAG == 0 && !position.is_square_attacked?(Square::E1, Colour::Black) && !position.is_square_attacked?(Square::F1, Colour::Black)
          yield Move::WhiteKingSideCastle
        end
        if all_occupation & Bitboard::WHITE_QUEEN_CASTLE_BLOCK_BB == 0 && position.flags & Position::WHITE_QUEEN_SIDE_CASTLE_FLAG == 0 && !position.is_square_attacked?(Square::E1, Colour::Black) && !position.is_square_attacked?(Square::D1, Colour::Black)
          yield Move::WhiteQueenSideCastle
        end
      else
        from_bb = position.pieces[Piece::Pawn.value] & position.colours[Colour::Black.value]
        while from_bb > 0
          from_id = from_bb.trailing_zeros_count
          from_mask = Bitboard.square_bb(from_id)
          from_rank = Bitboard.rank(from_id)
          if from_rank == Rank::RANK_2.value
            to_id = from_id - 8
            if all_occupation & Bitboard.square_bb(to_id) == 0
              yield Move.new_move(from_id, to_id, Piece::Pawn, Piece::None, Move.new_type(0, 1, 1, 1))
              yield Move.new_move(from_id, to_id, Piece::Pawn, Piece::None, Move.new_type(0, 1, 1, 0))
              yield Move.new_move(from_id, to_id, Piece::Pawn, Piece::None, Move.new_type(0, 1, 0, 1))
              yield Move.new_move(from_id, to_id, Piece::Pawn, Piece::None, Move.new_type(0, 1, 0, 0))
            end
            to_bb = Bitboard.pawn_attacks(Colour::Black, from_id) & position.colours[Colour::White.value]
            while to_bb > 0
              to_id = to_bb.trailing_zeros_count
              capture_type = position.type_on_square(to_id)
              yield Move.new_move(from_id, to_id, Piece::Pawn, capture_type, Move.new_type(1, 1, 1, 1))
              yield Move.new_move(from_id, to_id, Piece::Pawn, capture_type, Move.new_type(1, 1, 1, 0))
              yield Move.new_move(from_id, to_id, Piece::Pawn, capture_type, Move.new_type(1, 1, 0, 1))
              yield Move.new_move(from_id, to_id, Piece::Pawn, capture_type, Move.new_type(1, 1, 0, 0))
              to_bb &= (to_bb - 1)
            end
          else
            to_id = from_id - 8
            to_mask = Bitboard.square_bb(to_id)
            if all_occupation & to_mask == 0
              yield Move.new_move(from_id, to_id, Piece::Pawn, Piece::None, 0)

              # Double pawn push
              to_id = from_id - 16
              to_mask = Bitboard.square_bb(to_id)
              if from_rank == Rank::RANK_7.value && all_occupation & (to_mask) == 0
                yield Move.new_move(from_id, to_id, Piece::Pawn, Piece::None, Move.new_type(0, 0, 0, 1))
              end
            end
            to_bb = Bitboard.pawn_attacks(Colour::Black, from_id) & position.colours[Colour::White.value]
            while to_bb > 0
              to_id = to_bb.trailing_zeros_count
              yield Move.new_move(from_id, to_id, Piece::Pawn, position.type_on_square(to_id), Move.new_type(1, 0, 0, 0))
              to_bb &= (to_bb - 1)
            end
          end
          from_bb &= (from_bb - 1)
        end
        if position.ep_square != Square::NoSquare
          ep_bb = (Bitboard.square_bb(position.ep_square.value + 7) | Bitboard.square_bb(position.ep_square.value + 9)) & Bitboard::RANK_4_BB
          from_bb = ep_bb & position.pieces[Piece::Pawn.value] & position.colours[Colour::Black.value]
          while from_bb > 0
            from_id = from_bb.trailing_zeros_count
            yield Move.new_move(from_id, position.ep_square.value, Piece::Pawn, Piece::Pawn, Move.new_type(1, 0, 0, 1))
            from_bb &= (from_bb - 1)
          end
        end

        if all_occupation & Bitboard::BLACK_KING_CASTLE_BLOCK_BB == 0 && position.flags & Position::BLACK_KING_SIDE_CASTLE_FLAG == 0 && !position.is_square_attacked?(Square::E8, Colour::White) && !position.is_square_attacked?(Square::F8, Colour::White)
          yield Move::BlackKingSideCastle
        end
        if all_occupation & Bitboard::BLACK_QUEEN_CASTLE_BLOCK_BB == 0 && position.flags & Position::BLACK_QUEEN_SIDE_CASTLE_FLAG == 0 && !position.is_square_attacked?(Square::E8, Colour::White) && !position.is_square_attacked?(Square::D8, Colour::White)
          yield Move::BlackQueenSideCastle
        end
      end

      from_bb = position.pieces[Piece::Knight.value] & our_occupation
      # Knights
      while from_bb != 0
        from_id = from_bb.trailing_zeros_count
        to_bb = Bitboard.knight_attacks(from_id) & ~our_occupation
        while to_bb != 0
          to_id = to_bb.trailing_zeros_count
          to_mask = Bitboard.square_bb(to_id)
          if to_mask & their_occupation != 0
            yield Move.new_move(from_id, to_id, Piece::Knight, position.type_on_square(to_id), Move.new_type(1, 0, 0, 0))
          else
            yield Move.new_move(from_id, to_id, Piece::Knight, Piece::None, Move.new_type(0, 0, 0, 0))
          end
          to_bb &= (to_bb - 1)
        end
        from_bb &= (from_bb - 1)
      end
      # end of knights

      # Kings
      from_id = (position.pieces[Piece::King.value] & our_occupation).trailing_zeros_count
      to_bb = Bitboard.king_attacks(from_id) & ~our_occupation
      while to_bb != 0
        to_id = to_bb.trailing_zeros_count
        to_mask = Bitboard.square_bb(to_id)
        if to_mask & their_occupation != 0
          yield Move.new_move(from_id, to_id, Piece::King, position.type_on_square(to_id), Move.new_type(1, 0, 0, 0))
        else
          yield Move.new_move(from_id, to_id, Piece::King, Piece::None, Move.new_type(0, 0, 0, 0))
        end
        to_bb &= (to_bb - 1)
      end
      # end of Kings

      # Rooks
      from_bb = position.pieces[Piece::Rook.value] & our_occupation
      while from_bb != 0
        from_id = from_bb.trailing_zeros_count
        to_bb = Bitboard.rook_attacks(from_id, all_occupation) & ~our_occupation
        while to_bb != 0
          to_id = to_bb.trailing_zeros_count
          to_mask = Bitboard.square_bb(to_id)
          if to_mask & their_occupation != 0
            yield Move.new_move(from_id, to_id, Piece::Rook, position.type_on_square(to_id), Move.new_type(1, 0, 0, 0))
          else
            yield Move.new_move(from_id, to_id, Piece::Rook, Piece::None, Move.new_type(0, 0, 0, 0))
          end
          to_bb &= (to_bb - 1)
        end
        from_bb &= (from_bb - 1)
      end
      # end of Rooks

      # Bishops
      from_bb = position.pieces[Piece::Bishop.value] & our_occupation
      while from_bb != 0
        from_id = from_bb.trailing_zeros_count
        to_bb = Bitboard.bishop_attacks(from_id, all_occupation) & ~our_occupation
        while to_bb != 0
          to_id = to_bb.trailing_zeros_count
          to_mask = Bitboard.square_bb(to_id)
          if to_mask & their_occupation != 0
            yield Move.new_move(from_id, to_id, Piece::Bishop, position.type_on_square(to_id), Move.new_type(1, 0, 0, 0))
          else
            yield Move.new_move(from_id, to_id, Piece::Bishop, Piece::None, Move.new_type(0, 0, 0, 0))
          end
          to_bb &= (to_bb - 1)
        end
        from_bb &= (from_bb - 1)
      end
      # end of Bishops

      # Queens
      from_bb = position.pieces[Piece::Queen.value] & our_occupation
      while from_bb != 0
        from_id = from_bb.trailing_zeros_count
        to_bb = Bitboard.queen_attacks(from_id, all_occupation) & ~our_occupation
        while to_bb != 0
          to_id = to_bb.trailing_zeros_count
          to_mask = Bitboard.square_bb(to_id)
          if to_mask & their_occupation != 0
            yield Move.new_move(from_id, to_id, Piece::Queen, position.type_on_square(to_id), Move.new_type(1, 0, 0, 0))
          else
            yield Move.new_move(from_id, to_id, Piece::Queen, Piece::None, Move.new_type(0, 0, 0, 0))
          end
          to_bb &= (to_bb - 1)
        end
        from_bb &= (from_bb - 1)
      end
    end
  end
end

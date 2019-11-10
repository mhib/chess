require "./square"
require "./rank"
require "./file"

module Chess::Bitboard
  extend self

  RANK_1_BB = 0x00000000000000FF_u64
  RANK_2_BB = 0x000000000000FF00_u64
  RANK_3_BB = 0x0000000000FF0000_u64
  RANK_4_BB = 0x00000000FF000000_u64
  RANK_5_BB = 0x000000FF00000000_u64
  RANK_6_BB = 0x0000FF0000000000_u64
  RANK_7_BB = 0x00FF000000000000_u64
  RANK_8_BB = 0xFF00000000000000_u64

  FILE_A_BB = 0x0101010101010101_u64
  FILE_B_BB = 0x0202020202020202_u64
  FILE_C_BB = 0x0404040404040404_u64
  FILE_D_BB = 0x0808080808080808_u64
  FILE_E_BB = 0x1010101010101010_u64
  FILE_F_BB = 0x2020202020202020_u64
  FILE_G_BB = 0x4040404040404040_u64
  FILE_H_BB = 0x8080808080808080_u64

  WHITE_SQUARES = 0x55AA55AA55AA55AA_u64
  BLACK_SQUARES = 0xAA55AA55AA55AA55_u64

  {% for rank in (1..8) %}
    {% for file, idx in %w[A B C D E F G H] %}
      {{file.id}}{{rank.id}}_BB = 1u64 << {{(rank - 1) * 8 + idx}}
    {% end %}
  {% end %}

  WHITE_KING_CASTLE_BLOCK_BB  = F1_BB | G1_BB
  WHITE_QUEEN_CASTLE_BLOCK_BB = B1_BB | C1_BB | D1_BB
  BLACK_KING_CASTLE_BLOCK_BB  = F8_BB | G8_BB
  BLACK_QUEEN_CASTLE_BLOCK_BB = B8_BB | C8_BB | D8_BB

  PROMOTION_RANKS = RANK_1_BB | RANK_8_BB

  RANKS = Array[RANK_1_BB, RANK_2_BB, RANK_3_BB, RANK_4_BB, RANK_5_BB, RANK_6_BB, RANK_7_BB, RANK_8_BB]
  FILES = Array[FILE_A_BB, FILE_B_BB, FILE_C_BB, FILE_D_BB, FILE_E_BB, FILE_F_BB, FILE_G_BB, FILE_H_BB]

  SQUARE_BB          = Array(UInt64).new(64) { |idx| 1_u64 << idx.to_u64 }
  SQUARE_STRING      = Array(String).new(64) { |square| "" + ('a' + file(square)) + ('1' + rank(square)) }
  WHITE_PAWN_ATTACKS = Array(UInt64).new(64) { |i| white_pawns_attacks(1_u64 << i) }
  BLACK_PAWN_ATTACKS = Array(UInt64).new(64) { |i| black_pawns_attacks(1_u64 << i) }
  KNIGHT_ATTACKS     = Array(UInt64).new(64) { |i| knights_attacks(1_u64 << i) }
  KING_ATTACKS       = Array(UInt64).new(64) { |i| kings_attacks(1_u64 << i) }

  # Magic bitboards
  MAX_ROOK_BITS     = 12
  ROOK_SHIFT        = 64 - MAX_ROOK_BITS
  ROOK_ROW_SIZE     = 1 << MAX_ROOK_BITS
  MAX_BISHOP_BITS   = 9
  BISHOP_SHIFT      = 64 - MAX_BISHOP_BITS
  BISHOP_ROW_SIZE   = 1 << MAX_BISHOP_BITS
  ROOK_BLOCKER_MASK = [
    0x101010101017e_u64, 0x202020202027c_u64, 0x404040404047a_u64, 0x8080808080876_u64, 0x1010101010106e_u64, 0x2020202020205e_u64, 0x4040404040403e_u64, 0x8080808080807e_u64,
    0x1010101017e00_u64, 0x2020202027c00_u64, 0x4040404047a00_u64, 0x8080808087600_u64, 0x10101010106e00_u64, 0x20202020205e00_u64, 0x40404040403e00_u64, 0x80808080807e00_u64,
    0x10101017e0100_u64, 0x20202027c0200_u64, 0x40404047a0400_u64, 0x8080808760800_u64, 0x101010106e1000_u64, 0x202020205e2000_u64, 0x404040403e4000_u64, 0x808080807e8000_u64,
    0x101017e010100_u64, 0x202027c020200_u64, 0x404047a040400_u64, 0x8080876080800_u64, 0x1010106e101000_u64, 0x2020205e202000_u64, 0x4040403e404000_u64, 0x8080807e808000_u64,
    0x1017e01010100_u64, 0x2027c02020200_u64, 0x4047a04040400_u64, 0x8087608080800_u64, 0x10106e10101000_u64, 0x20205e20202000_u64, 0x40403e40404000_u64, 0x80807e80808000_u64,
    0x17e0101010100_u64, 0x27c0202020200_u64, 0x47a0404040400_u64, 0x8760808080800_u64, 0x106e1010101000_u64, 0x205e2020202000_u64, 0x403e4040404000_u64, 0x807e8080808000_u64,
    0x7e010101010100_u64, 0x7c020202020200_u64, 0x7a040404040400_u64, 0x76080808080800_u64, 0x6e101010101000_u64, 0x5e202020202000_u64, 0x3e404040404000_u64, 0x7e808080808000_u64,
    0x7e01010101010100_u64, 0x7c02020202020200_u64, 0x7a04040404040400_u64, 0x7608080808080800_u64, 0x6e10101010101000_u64, 0x5e20202020202000_u64, 0x3e40404040404000_u64, 0x7e80808080808000_u64,
  ] of UInt64
  ROOK_MAGIC_INDEX = [
    0x100104100800020_u64, 0x2040006000100040_u64, 0x410004205100c008_u64, 0x210180050021000_u64, 0x8008100a010440_u64, 0x2200420030040401_u64, 0x80108200490402_u64, 0x200010184004026_u64,
    0x40282002a0093001_u64, 0x801800c40108a200_u64, 0xa404900844000808_u64, 0x50200232002004_u64, 0x90080110080040_u64, 0x89600480f020004_u64, 0xc201441804614_u64, 0x80800060800100_u64,
    0x1880002040001006_u64, 0x42402000100800_u64, 0x691e0070100c0400_u64, 0x2010000841140084_u64, 0x1000800891800c0_u64, 0xa2014100040002a2_u64, 0x228028040048c44_u64, 0x14004200802400c_u64,
    0x8020044340012011_u64, 0x4020050a4088024_u64, 0x13403018084100_u64, 0x2000300604100400_u64, 0x20080608000100_u64, 0xc0006010040cd_u64, 0x1012088020001_u64, 0x81080c1841000040_u64,
    0x40a0418000102800_u64, 0x40000810200c0020_u64, 0x1012000608200400_u64, 0x1000040022080018_u64, 0x80d010ae8a000200_u64, 0x4444118940004_u64, 0x100020030202060_u64, 0x640902089400500_u64,
    0xa000142042848000_u64, 0x80e00008405010_u64, 0x54402008022004_u64, 0x1230020800101000_u64, 0x108184201000880_u64, 0x8140008010050400_u64, 0x504080242500a_u64, 0x1015000022408009_u64,
    0x4044050102210408_u64, 0x284811024204_u64, 0x20c04a4124080040_u64, 0x14040003080040_u64, 0x1003210001029020_u64, 0x2005020014000180_u64, 0x22010008489120_u64, 0x100088000504220_u64,
    0x30410480009021_u64, 0x98100400c802111_u64, 0x801406000081101_u64, 0x402061200204002_u64, 0x8000100100044801_u64, 0x182020400801839_u64, 0x4100112050081604_u64, 0x5000062804213_u64,
  ] of UInt64
  BISHOP_BLOCKER_MASK = [
    0x40201008040200u64, 0x402010080400u64, 0x4020100a00u64, 0x40221400u64, 0x2442800u64, 0x204085000u64, 0x20408102000u64, 0x2040810204000u64,
    0x20100804020000u64, 0x40201008040000u64, 0x4020100a0000u64, 0x4022140000u64, 0x244280000u64, 0x20408500000u64, 0x2040810200000u64, 0x4081020400000u64,
    0x10080402000200u64, 0x20100804000400u64, 0x4020100a000a00u64, 0x402214001400u64, 0x24428002800u64, 0x2040850005000u64, 0x4081020002000u64, 0x8102040004000u64,
    0x8040200020400u64, 0x10080400040800u64, 0x20100a000a1000u64, 0x40221400142200u64, 0x2442800284400u64, 0x4085000500800u64, 0x8102000201000u64, 0x10204000402000u64,
    0x4020002040800u64, 0x8040004081000u64, 0x100a000a102000u64, 0x22140014224000u64, 0x44280028440200u64, 0x8500050080400u64, 0x10200020100800u64, 0x20400040201000u64,
    0x2000204081000u64, 0x4000408102000u64, 0xa000a10204000u64, 0x14001422400000u64, 0x28002844020000u64, 0x50005008040200u64, 0x20002010080400u64, 0x40004020100800u64,
    0x20408102000u64, 0x40810204000u64, 0xa1020400000u64, 0x142240000000u64, 0x284402000000u64, 0x500804020000u64, 0x201008040200u64, 0x402010080400u64,
    0x2040810204000u64, 0x4081020400000u64, 0xa102040000000u64, 0x14224000000000u64, 0x28440200000000u64, 0x50080402000000u64, 0x20100804020000u64, 0x40201008040200u64,
  ] of UInt64
  BISHOP_MAGIC_INDEX = [
    0x20422488000802u64, 0x212014400880212u64, 0x8009802200030580u64, 0x6ac028460200400u64, 0x5492810000020u64, 0x200450026a228060u64, 0x4040908201200380u64, 0x10800a004800u64,
    0x220101106008u64, 0x15826a100122041u64, 0x280020064420u64, 0x100202082088000u64, 0x10060040ac008004u64, 0x8835028080400cu64, 0x4100040020821008u64, 0x10012511002400u64,
    0x201c9801840820u64, 0x8120022022006810u64, 0x802910802240au64, 0x1084428b2c00d00u64, 0x20200202101800u64, 0x882900601000u64, 0x4154088400808028u64, 0x2028810045042800u64,
    0x8410301010410208u64, 0x2209010440208u64, 0x1004004000810d20u64, 0x6004040002401080u64, 0x840002812010u64, 0x1000820804040420u64, 0x4200610101040200u64, 0x1004202002140028u64,
    0x22204012209020u64, 0x20180080040289u64, 0x1200208040300404u64, 0x2040108040100u64, 0x9090400420020u64, 0x40004a9580084010u64, 0x48200c21420900du64, 0x4528021002000450u64,
    0x900060008211u64, 0x4451004081540u64, 0x1000230020800880u64, 0x5084390094bu64, 0x2020042c1010u64, 0x4440a8048408244u64, 0x21840a044000080u64, 0x868004184900u64,
    0x804c0180400401u64, 0x208100224010a080u64, 0xc109044008010808u64, 0x841001240202008u64, 0x12d248403a028000u64, 0xc8020c10046u64, 0x460034506028000u64, 0x4591080010108c10u64,
    0x11005000e000u64, 0x8400240201500202u64, 0x81024020100u64, 0x2200010240080800u64, 0x42c02110a114c41u64, 0x3008520090801084u64, 0x8002014c804810c0u64, 0x1009205048004002u64,
  ] of UInt64
  ROOK_ATTACKS = begin
    blocker_board = ROOK_BLOCKER_MASK.each_with_object([] of Array(UInt64)) do |position, res|
      res << bitboard_combinations(position)
    end
    move_board = blocker_board.map_with_index do |boards, y|
      boards.map_with_index do |board, x|
        generate_sliding_moveboard(y, board, ROOK_BLOCKER_MASK[y], [->south(UInt64), ->north(UInt64), ->east(UInt64), ->west(UInt64)])
      end
    end
    rook_attacks = Array(UInt64).new(64 * ROOK_ROW_SIZE, 0)
    ROOK_MAGIC_INDEX.each_with_index do |magic, idx|
      blocker_board[idx].each_with_index do |el, inner_idx|
        mult = (el.to_u64 &* magic.to_u64).to_u64 >> ROOK_SHIFT
        rook_attacks[idx.to_u64 &* ROOK_ROW_SIZE + mult] = move_board[idx][inner_idx]
      end
    end
    rook_attacks
  end

  BISHOP_ATTACKS = begin
    blocker_board = BISHOP_BLOCKER_MASK.each_with_object([] of Array(UInt64)) do |position, res|
      res << bitboard_combinations(position)
    end
    move_board = blocker_board.map_with_index do |boards, y|
      boards.map_with_index do |board, x|
        generate_sliding_moveboard(y, board, BISHOP_BLOCKER_MASK[y], [->south_east(UInt64), ->north_east(UInt64), ->south_west(UInt64), ->north_west(UInt64)])
      end
    end
    bishop_attacks = Array(UInt64).new(64 * BISHOP_ROW_SIZE, 0)
    BISHOP_MAGIC_INDEX.each_with_index do |magic, idx|
      blocker_board[idx].each_with_index do |el, inner_idx|
        mult = (el.to_u64 &* magic.to_u64).to_u64 >> BISHOP_SHIFT
        bishop_attacks[idx.to_u64 &* BISHOP_ROW_SIZE + mult] = move_board[idx][inner_idx]
      end
    end
    bishop_attacks
  end

  def file(square : Number)
    square & 7
  end

  def file(square : Square)
    File.new(file(square.value))
  end

  def rank(square : Number)
    square >> 3
  end

  def rank(square : Square)
    Rank.new(rank(square.value))
  end

  def more_than_one?(bb)
    bb != 0 && ((bb - 1) & bb) != 0
  end

  def square_string(square : Number)
    SQUARE_STRING[square]
  end

  def north_west(bb)
    (bb & ~RANK_8_BB & ~FILE_A_BB) << 7
  end

  def north(bb)
    (bb & ~RANK_8_BB) << 8
  end

  def north_east(bb)
    (bb & ~RANK_8_BB & ~FILE_H_BB) << 9
  end

  def east(bb)
    (bb & ~FILE_H_BB) << 1
  end

  def west(bb)
    (bb & ~FILE_A_BB) >> 1
  end

  def south_west(bb)
    (bb & ~RANK_1_BB & ~FILE_A_BB) >> 9
  end

  def south(bb)
    (bb & ~RANK_1_BB) >> 8
  end

  def south_east(bb)
    (bb & ~RANK_1_BB & ~FILE_H_BB) >> 7
  end

  def kings_attacks(bb)
    return north_west(bb) | north(bb) | north_east(bb) |
      east(bb) | west(bb) |
      south_west(bb) | south(bb) | south_east(bb)
  end

  def knights_attacks(bb)
    l1 = bb >> 1 & 0x7f7f7f7f7f7f7f7f_u64
    l2 = bb >> 2 & 0x3f3f3f3f3f3f3f3f_u64
    r1 = bb << 1 & 0xfefefefefefefefe_u64
    r2 = bb << 2 & 0xfcfcfcfcfcfcfcfc_u64
    h1 = l1 | r1
    h2 = l2 | r2
    (h1 << 16) | (h1 >> 16) | (h2 << 8) | (h2 >> 8)
  end

  def white_pawns_attacks(bb)
    north_west(bb) | north_east(bb)
  end

  def white_pawns_moves(bb, occupancy)
    (north(bb) | ((north(north(bb)) & RANK_4_BB) & ~north(occupancy & RANK_3_BB))) & ~occupancy
  end

  def black_pawns_attacks(bb)
    south_west(bb) | south_east(bb)
  end

  def black_pawns_moves(bb, uint64)
    (south(bb) | ((south(south(bb)) & RANK_5_BB) & ~south(occupancy & RANK_6_BB))) & ~occupancy
  end

  def square_bb(square : Number)
    SQUARE_BB[square]
  end

  def black_pawn_attacks(square : Number)
    BLACK_PAWN_ATTACKS[square]
  end

  def white_pawn_attacks(square : Number)
    WHITE_PAWN_ATTACKS[square]
  end

  PAWN_ATTACKS = BLACK_PAWN_ATTACKS + WHITE_PAWN_ATTACKS

  def pawn_attacks(colour, square : Number)
    PAWN_ATTACKS[colour.value * 64 + square]
  end

  def pawn_attacks(colour, square : Square)
    PAWN_ATTACKS[colour.value * 64 + square.value]
  end

  def knight_attacks(square : Number)
    KNIGHT_ATTACKS[square]
  end

  def king_attacks(square : Number)
    KING_ATTACKS[square]
  end

  def rook_attacks(square : Number, occupancy)
    ROOK_ATTACKS[
      square &* ROOK_ROW_SIZE +
      (((ROOK_BLOCKER_MASK[square] & occupancy) &* ROOK_MAGIC_INDEX[square]) >> ROOK_SHIFT),
    ]
  end

  def bishop_attacks(square : Number, occupancy)
    BISHOP_ATTACKS[
      square &* BISHOP_ROW_SIZE +
      (((BISHOP_BLOCKER_MASK[square] & occupancy) &* BISHOP_MAGIC_INDEX[square]) >> BISHOP_SHIFT),
    ]
  end

  def queen_attacks(square : Number, occupancy)
    rook_attacks(square, occupancy) | bishop_attacks(square, occupancy)
  end

  {% for name in %w[square_bb black_pawn_attacks white_pawn_attacks knight_attacks king_attacks square_string] %}
    def {{name.id}}(square : Square)
      {{name.id}}(square.value)
    end
  {% end %}

  {% for name in %w[rook_attacks bishop_attacks] %}
    def {{name.id}}(square : Square, occupancy)
      {{name.id}}(square.value, occupancy)
    end
  {% end %}

  def bitboard_combinations(bb)
    if bb == 0
      return [0u64]
    end

    right_hand_bit = bb & ((~bb) + 1) # bb & -bb
    recursive = bitboard_combinations(bb & ~right_hand_bit)
    res = recursive.dup
    recursive.each do |el|
      res << (el | right_hand_bit)
    end
    res
  end

  def generate_sliding_moveboard(square, board, blocker, directions)
    mask = 1_u64 << square
    res = 0_u64
    directions.each do |direction|
      tmpMask = direction.call(mask)
      while true
        res |= tmpMask
        break if blocker & tmpMask == 0 || board & tmpMask > 0
        tmpMask = direction.call(tmpMask)
      end
    end
    res
  end
end

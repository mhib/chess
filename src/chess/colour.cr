enum Chess::Colour
  Black
  White

  def flip
    Colour.new(value ^ 1)
  end
end

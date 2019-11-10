enum Chess::Square
  {% for rank in (1..8) %}
    {% for file in %w[A B C D E F G H] %}
      {{file.id}}{{rank.id}}
    {% end %}
  {% end %}

  NoSquare
end

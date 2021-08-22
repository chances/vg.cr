require "./../src/vg"
include VG

canvas = Canvas.new 800, 600
canvas.fill Color.new 0x0 # Equivalent to Colors::BLACK

rnd = Random.new 42
rects = Array(RoundRect(Float32)).new 40

def random_round_rect(rnd : Random)
  x = rnd.rand(120_f64..680_f64)
  y = rnd.rand(120_f64..680_f64)
  w = rnd.rand(12_f64..100_f64)
  h = rnd.rand(12_f64..100_f64)
  c = rnd.rand(2_f64..(w < h ? w : h) / 2)
  return RoundRect.new x - w, y - h, x + w, y + h, c, c
end

rects.each_index do |i|
  rect : RoundRect?
  rect_intersects = ->(index, other) { index < i ? rect.outset(8, true).intersects(other) : false }
  while rect.is_nil? || rects.map_with_index(rect_intersects).any?
    rect = random_round_rect(rnd)
  end
  rects[i] = rect.not_nil!
end

rects.each do |rect|
  canvas.draw(
    rect.as_path.append(rect.inset(8, true).as_path.retro),
    rnd.rand(0..0xFFFFFFFF) | 0xff000000,
    winding: WindingRule.NonZero,
  )
end

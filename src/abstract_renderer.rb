class AbstractRenderer
  def initialize(size)
    @size = size    
  end

  def draw_motion_blur(x, l, v, dt, &blk)    
    return if l <= 0

    shutter = 1

    x0 = x - 0.5 * dt * shutter * v
    x1 = x + 0.5 * dt * shutter * v

    x0, x1 = x1, x0 if x0 > x1

    w0 = x0 - 0.5 * l
    w1 = x0 + 0.5 * l
    w2 = x1 - 0.5 * l
    w3 = x1 + 0.5 * l

    w1, w2 = w2, w1 if w1 > w2    

    integral = 0.5 * (w1 - w0) + 0.5 * (w3 - w2) + (w2 - w1)
    s = l / integral

    linear_ramp(w0, w1, 0, s, &blk)
    linear_ramp(w1, w2, s, s, &blk)
    linear_ramp(w2, w3, s, 0, &blk)
  end

  def linear_ramp(x0, x1, s0, s1)
    return if x0 == x1

    if x0 > x1
      x0, x1 = x1, x0
      s0, s1 = s1, s0
    end

    p0 = (x0 + 0.5).floor
    p1 = (x1 + 0.5).floor

    sl = (s1 - s0) / (x1 - x0)

    (p0..p1).each do |i|
      next if i < 0 || i >= @size

      px0 = i - 0.5
      px1 = i + 0.5

      cx0 = px0 >= x0 ? px0 : x0
      cx1 = px1 <= x1 ? px1 : x1      

      cs0 = sl * (cx0 - x0) + s0
      cs1 = sl * (cx1 - x0) + s0

      frac = cx1 - cx0
      s = 0.5 * (cs0 + cs1)

      yield i, frac * s
    end
  end
end
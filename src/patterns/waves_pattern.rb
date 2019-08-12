class WavesPattern < Pattern
  attr_reader :values
  attr_reader :positions
  attr_reader :velocities

  def initialize(strip_count)
    super(strip_count)

    @values = [0] * (128 * 128)

    @positions = [0] * (128 * 128)
    @last_positions = [0] * (128 * 128)

    @velocities = [0] * (128 * 128)

    @t = 0
    @i = 0

    @wt = 0
    @rx = Random.rand(1...127)
    @ry = Random.rand(1...104)
  end

  def build_controller(i)
    StripController.new(self, @strip_count, i)
  end

  def step(dt)
    super(dt)

    st = @wt * 4

    if st <= 1
      c = Math.cos(Math::PI * (st + 0.5))

      @wp = 200000 * c
    else
      @wp = 0
    end

    if @wt >= 3
      @wt = 0
      @rx = Random.rand(1...127)
      @ry = Random.rand(1...104)
    end

    # step_1st_order(dt)
    step_2nd_order(dt)

    @t += dt
    @wt += dt
    @i += 1
  end

  def step_1st_order(dt)
    c2 = 1800

    (1...127).each do |y|
      (1...127).each do |x|
        idx = 128 * y + x
        pos = @positions[idx]
        last = @last_positions[idx]

        s = @positions[idx - 1] +
            @positions[idx + 1] +
            @positions[idx - 128] +
            @positions[idx + 128]

        # v = (@positions[idx] - @last_positions[idx]) / dt
        # v += f * dt
        #np = @positions + v * dt

        k = 0.25 * c2 * dt * dt
        np = k * s + (2 - 4 * k) * pos - last

        # np += dt * dt * 0.05 * -pos

        # choose k = 0.5
        # np = 0.5 * s - @last_positions[idx]
        
        @last_positions[idx] = np
      end
    end

    temp = @positions
    @positions = @last_positions
    @last_positions = temp

    (1...127).each do |y|
      (1...127).each do |x|
        idx = 128 * y + x

        @positions[idx] *= 0.99
        @last_positions[idx] *= 0.99
      end
    end
  end

  def step_2nd_order(dt)
    c2 = 1500
    vmax = 5000

    state_decay = 0.6
    hfreq_decay = 0.01


    state_decay_b = Math.log(state_decay)
    state_decay_m = Math.exp(state_decay_b * dt)

    hfreq_decay_b = Math.log(hfreq_decay)
    hfreq_decay_m = Math.exp(hfreq_decay_b * dt)

    (1...127).each do |y|
      (1...127).each do |x|
        idx = 128 * y + x
        @values[idx] = 0
      end
    end

    center_weight = hfreq_decay_m

    (0...2).each do
      (1...104).each do |y|
        (1...127).each do |x|
          idx = 128 * y + x
          pos = @positions[idx]

          s = @positions[idx - 1] +
              @positions[idx + 1] +
              @positions[idx - 128] +
              @positions[idx + 128]

          c = center_weight * pos + (1 - center_weight) * 0.25 * s
          @last_positions[idx] = c                    

          s -= 4 * pos
          s /= 4

          f = c2 * s

          v = @velocities[idx]
          v += f * dt
          v *= state_decay_m

          v = vmax if v > vmax
          v = -vmax if v < -vmax

          @velocities[idx] = v
        end
      end       

      idx = 128 * @ry + @rx
      @velocities[idx] += @wp * dt

      (1...104).each do |y|
        (1...127).each do |x|
          idx = 128 * y + x               
          @positions[idx] = @last_positions[idx] + @velocities[idx] * dt
          @positions[idx] *= state_decay_m    

          @values[idx] = 0.5 * @positions[idx]
        end
      end

      # center_weight = hfreq_decay_m

      # (1...104).each do |y|
      #   (1...127).each do |x|
      #     idx = 128 * y + x
      #     pos = @last_positions[idx]

      #     s = @last_positions[idx - 1] +
      #         @last_positions[idx + 1] +
      #         @last_positions[idx - 128] +
      #         @last_positions[idx + 128]

      #     c = center_weight * pos + (1 - center_weight) * 0.25 * s

      #     @positions[idx] = c
      #     @positions[idx] *= state_decay_m

      #     @values[idx] = 0.5 * @positions[idx]
      #   end
      # end      
    end

    # weight = 8

    # (1...127).each do |y|
    #   (1...127).each do |x|
    #     idx = 128 * y + x

    #     s = @last_positions[idx - 1] +
    #         @last_positions[idx + 1] +
    #         @last_positions[idx - 128] +
    #         @last_positions[idx + 128]

    #     v = (weight * @last_positions[idx] + s) / (weight + 4)

    #     @positions[idx] = v
    #   end
    # end
  end

  def print_positions
    # puts "\e[H\e[2J"
    
    puts "TIME: #{@t}"

    return

    (0...32).each do |y|
      puts (0...32).map { |x|
        idx = 128 * y + x
        pos = @positions[idx]
        # pos > 0 ? '+' : ' '
        "%5.2f" % pos
      }.join(" ")
    end
  end

  def set_position(x, y, pos)
    ix = (x + 128) % 128
    iy = (y + 128) % 128
    idx = 128 * iy + ix
    @positions[idx] = pos
  end

  class StripController
    def initialize(pattern, strip_count, idx)
      @pattern = pattern
      @strip_count = strip_count
      @idx = idx

      @alphas = [0] * 64
      @wash_rgbs = (0...64).map { [0, 0, 0] }
      @output_rgbs = (0...64).map { [0, 0, 0] }      

      @hue = 0
    end

    def pixels
      @output_rgbs
    end

    def halt!

    end

    def step(dt)
      step_color(dt)

      render_positions
      render_wash
      render_output
    end

    def step_color(dt)
      sum = @alphas.inject(&:+)
      sum /= 64

      if sum < 0.1
        @hue += 30 * dt
      end
    end

    def render_positions
      positions = @pattern.values
      samples = [0.0] * 21

      (0...64).each do |i|        
        (0...4).each do |j|
          (0...7).each do |k|

            x = 40 * @idx + j + 1
            y = 2 * i + (j - 1)

            idx = 128 * y + x
            si = 7 * j + k

            # gx = (positions[idx - 1] - positions[idx + 1]) / 2
            # gy = (positions[idx - 128] - positions[idx + 128]) / 2

            # n = [-gx, -gy, 1]
            # norm = Math.sqrt(n[0] * n[0] + n[1] * n[1] + n[2] * n[2])
            # n[0] /= norm
            # n[1] /= norm
            # n[2] /= norm


            # dot = n[0] * l[0] + n[1] * l[1] + n[2] * l[2]
            # q = dot ** 5

            # val = 10 * q
            # val = [[val, 0].max, 1].min

            # sum += val

            if y >= 0 && y < 128
              samples[si] = positions[idx]
            else
              samples[si] = 0
            end
          end
        end

        samples.sort!

        avg = samples.inject(&:+) / 21
        max = samples.max
        med = samples[7]

        low = 0.01
        high = 1

        val = (med - low) / (high - low)

        val = [[val, 0].max, 1].min

        @alphas[i] = val        
      end
    end

    def render_wash
      color_rgb = RGB::Color.new(@hue, 1, 0.5).to_rgb

      (0...64).each do |i|
        l = @alphas[i]
        w = @wash_rgbs[i]

        (0...3).each do |j|                     
          w[j] = w[j] * (1 - l) + color_rgb[j] * l
        end
      end
    end

    def render_output
      (0...64).each do |i|
        o = @output_rgbs[i]
        w = @wash_rgbs[i]
        a = @alphas[i]

        a = 0 if a < 0
        a = 1 if a > 1

        (0...3).each do |j|
          o[j] = w[j] * (1 - a) + 255 * a
          w[j] *= 0.9
        end
      end
    end       
  end
end

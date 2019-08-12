class StrobePattern < Pattern
  attr_reader :rate

  def initialize(strip_count)
    super(strip_count)

    @rate = 10000
    @t = 0

    @hue_initial = Random.rand(360)
  end

  def step(dt)
    super

    @t += dt
  end

  def crescendo
    st = @t / 30
    f = 0.5 * (-Math.cos(2 * Math::PI * st) + 1)
    f ** 2
  end

  def rate  
    0.5 + 20 * crescendo
  end

  def hue_center
    (@t / 30).floor * 160 + @hue_initial
  end

  def build_controller(i)
    StrobeController.new(self, i)
  end

  class StrobeController
    attr_reader :pixels    

    def initialize(pattern, i)
      @pattern = pattern
      @index = i
      @halted = false

      @t = 0
      @choked_until = 0

      @alphas = [0] * 112
      @wash_rgbs = (0...112).map { [0, 0, 0] }
      @output_rgbs = (0...112).map { [0, 0, 0] }

      @last_lit = -112
    end

    def pixels
      @output_rgbs
    end

    def halt!
      @halted = true
    end    

    def step(dt)

      # Step

      rate = @pattern.rate
      lit = false

      if @t >= @choked_until && !@halted
        prob = rate * dt
        lit = Random.rand < prob
      end

      if lit
        min_choke = 1
        max_choke = 5

        choke = Random.rand(min_choke..max_choke) / rate
        choke = [choke, 1].min

        @choked_until = @t + choke
      end

      @t += dt

      # Render   

      @alphas = [0] * 112

      if lit
        hue = @pattern.hue_center + Random.rand(-30...30)
        color_rgb = RGB::Color.new(hue, 1, 0.3).to_rgb

        spread = 16 + [20 / rate, 40].min
        center = 32

        (0...10).each do
          center = 27 + spread * Random.rand(-0.5..0.5)
          break if (center - @last_lit).abs > 10
        end

        @last_lit = center

        length = Random.rand(16...40) + 16 * @pattern.crescendo

        low = center - (length / 2).floor
        high = center + (length / 2).floor

        (0...64).each do |i|
          next if i < low || high < i

          f = (i - low).to_f / (high - low)
          l = 1 * Math.cos(Math::PI * (f - 0.5))

          l = 1 if l > 1
          l = 0 if l < 0

          @alphas[i] = l

          w = @wash_rgbs[i]

          (0...3).each do |j|                     
            w[j] = w[j] * (1 - l) + color_rgb[j] * l
          end
        end
      end

      render_output
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

    def halt!
      @halted = true
    end
  end
end

class AscendingPattern < Pattern
  def initialize(strip_count)
    @hue_initial = Random.rand(360)
    
    super(strip_count)    
  end

  def build_controller(i)
    Controller1.new(@hue_initial)
  end
end

class Controller1
  class Entity
    attr_reader :p, :v, :l
    attr_reader :channels

    def initialize(hc=0)
      @l = Random.rand(1.0..2.0)
      @v = 5.0 * @l
      @p = -0.5 * @l - 0.1 * Random.rand(@v)
      
      hue = Random.rand(30.0) + hc

      if Random.rand < 0.2
        hue += Random.rand < 0.5 ? 30 : -30
      end

      @channels = RGB::Color.new(hue, 1, 0.5).to_rgb.map { |ch| ch / 255.0 }
    end

    def step(dt)
      @p += dt * @v    
    end

    def alive?
      @p < 112 + 0.5 * @l
    end
  end

  CENTERS = (0...20).map { |i| 160 * i }

  def initialize(hue_initial)
    @t = 0    
    @hue_t = 0
    @entities = []
    @halted = false
    
    @alphas = [0] * 112
    @wash_rgbs = (0...112).map { [0, 0, 0] }
    @output_rgbs = (0...112).map { [0, 0, 0] }

    @hue_initial = hue_initial

    clear

    @r = AbstractRenderer.new(112)
  end

  def step(dt)
    clear

    step_entities(dt)
    spawn_entities

    draw_entities(dt)
    render_output
  end

  def halt!
    @halted = true
  end

  def pixels
    @output_rgbs
  end

  private

  def clear
    (0...112).each do |i|      
      @alphas[i] = 0
    end
  end

  def spawn_entities
    return if @entities.size > 10 || @halted

    if Random.rand < 0.1
      c = current_hue_center
      @entities << Entity.new(c)
    end
  end

  def step_entities(dt)
    @entities.each { |e| e.step(dt) }
    @entities.select!(&:alive?)    

    @t += dt
    @hue_t += 0.05 * dt
    @hue_t =- CENTERS.size while @hue_t > CENTERS.size
  end

  def draw_entities(dt)
    @entities.each do |e|
      @r.draw_motion_blur(e.p, e.l, 3 * e.v, dt) do |i, s|
        @alphas[i] += s

        w = @wash_rgbs[i]

        (0...3).each do |j|                     
          w[j] = w[j] * (1 - s) + e.channels[j] * s
        end
      end
    end
  end

  def render_output
    (0...112).each do |i|
      o = @output_rgbs[i]
      w = @wash_rgbs[i]
      a = @alphas[i]

      a = 0 if a < 0
      a = 1 if a > 1

      r = 0.5 * a

      (0...3).each do |j|
        o[j] = 255.0 * (w[j] * (1 - r) + 1 * r)
        w[j] *= 0.85
      end
    end
  end

  def current_hue_center
    num = CENTERS.size    
    hue_f = @hue_t - @hue_t.floor
    hue_i1 = @hue_t.floor % num
    hue_i2 = (hue_i1 + 1) % num

    hue1 = CENTERS[hue_i1]
    hue2 = CENTERS[hue_i2]

    out = if hue_f < 0.75
      hue1
    else
      d = hue_f - 0.75 / 0.25
      (hue2 - hue1) * d + hue1
    end

    out + @hue_initial
  end
end

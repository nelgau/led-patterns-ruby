class MeltingPattern < Pattern
  def initialize(strip_count)
    @hue_initial = Random.rand(360)
    
    super(strip_count)
  end

  def build_controller(i)
    Controller2.new(@hue_initial)
  end
end

class Controller2
  class Entity
    FADE_TIME = 1

    HUE_RANGES = [
      150...330,
      20...40
    ]


    attr_reader :low, :high
    attr_reader :hue, :alpha

    def initialize(hc)
      length = Random.rand(4..16)    
      @low = Random.rand(0..112 - length)
      @high = low + length

      #@hue = Random.rand(720.0) + hc
    
      range_index = Random.rand(HUE_RANGES.count)
      @hue = Random.rand(HUE_RANGES[range_index])

      @fade_time = Random.rand(0.75...1.25)
      @delay = Random.rand(1.0)

      @alpha = 0
      @b_alpha = 1

      @t = 0
    end

    def step(dt)
      @t += dt

      if @b_alpha > 0

        x = @t / @fade_time
        x = 1 if x > 1
        t_alpha = x * x * (3 - 2 * x)

        ct_alpha = 1 - t_alpha
        cf_alpha = ct_alpha / @b_alpha        
        @b_alpha *= cf_alpha

        @alpha = 1 - cf_alpha
      else
        @alpha = 0
      end
    end

    def alive?
      @t <= @fade_time + @delay
    end
  end

  def initialize(hue_initial)
    @entities = []
    @halted = false

    @colors = (0...112).map { RGB::Color.new(0, 0, 0) }

    @hue_initial = hue_initial
  end

  def step(dt)
    step_entities(dt)
    spawn_entities

    update_surface(dt)
    draw_entities(dt)    
    render_output
  end

  def halt!
    @halted = true
  end

  def spawn_entities
    return if @entities.any? || @halted

    @entities << Entity.new(@hue_initial)
  end

  def step_entities(dt)
    @entities.each { |e| e.step(dt) }
    @entities.select!(&:alive?)    
  end

  def draw_entities(dt)
    @entities.each do |e|
      (e.low...e.high).each do |i|
        f = (i - e.low).to_f / (e.high - e.low)
        l = 0.4 + 0.4 * Math.cos(Math::PI * (f - 0.5))

        b_rgbs = @colors[i].to_rgb
        f_rgbs = RGB::Color.new(e.hue, 1.0, l).to_rgb

        (0...3).each do |j|
          b_rgbs[j] = e.alpha * f_rgbs[j] + (1 - e.alpha) * b_rgbs[j]
        end
        
        @colors[i] = RGB::Color.from_rgb(*b_rgbs)
      end
    end
  end

  def update_surface(dt)
    hues = (0...112).map { |i| @colors[i].h }
    hf = 1 - dt * 0.8

    # (0...112).each do |i|
    #   neighbors = (1...6).map { |d| [i - d] }.flatten
    #   neighbors.select! { |n| n >= 0 && n < 64 && @colors[n].l > 0.1 }
    #   next if neighbors.empty?

    #   neighbor_hues = neighbors.map { |n| hues[n] }
    #   avg = neighbor_hues.inject(&:+) / neighbors.count.to_f
    #   @colors[i].h = hf * @colors[i].h + (1.0 - hf) * avg
    # end 

    (0...112).each do |i|
      #@colors[i].h = @colors[i].h + dt * 5 
      @colors[i].darken_percent!(dt * 15)
    end
  end

  def render_output

  end

  def pixels
    @colors.map(&:to_rgb)
  end
end

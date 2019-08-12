$:.unshift File.dirname(__FILE__)

require 'src/abstract_renderer.rb'
require 'src/pattern.rb'
require 'src/patterns.rb'

require 'faderuby'
require 'rgb'

class Application
  TIME_STEP = 1.0 / 30
  STRIP_COUNT = 4

  PATTERN_CLASSES = [
    WavesPattern,    
    AscendingPattern,
    MeltingPattern,
    StrobePattern,
  ]

  RUN_DURATION  = 60
  HALT_DURATION = 1
  FADE_DURATION = 5

  STAGES = [
    { :transition => :run_pattern,   :duration => RUN_DURATION }, 
    { :transition => :halt_pattern,  :duration => HALT_DURATION },
    { :transition => :fade_patterns, :duration => FADE_DURATION }
  ]

  def self.run!
    self.new.run
  end

  def initialize
    @client = FadeRuby::Client.new('172.16.0.83', 7890)

    @patterns = []      

    @stage_index = -1
    @stage_time = 0

    @fading = false
    @fade_duration = 0
    @fade_time = 0

    @pattern_index = 0

    @output = []

    add_pattern(@pattern_index)  
  end

  def run
    start_time = Time.now

    loop do
      advance_state(TIME_STEP)
      render_output

      end_time = Time.now
      loop_interval = end_time - start_time
      delay_time = TIME_STEP - loop_interval

      if delay_time > 0
        sleep TIME_STEP
      else
        puts "WARN: Fell behind by #{-delay_time} second(s)."
      end

      start_time = Time.now
      send_output      
    end
  end

  def advance_state(dt)
    step_patterns(dt)
    step_stage(dt)
    step_fade(dt)
  end

  def step_patterns(dt)
    @patterns.each do |p|
      p.step(dt)
    end
  end

  def run_pattern
    @fading = false    
    remove_first_pattern
  end

  def halt_pattern
    @patterns[0].halt!
  end

  def fade_patterns
    @fading = true
    @fade_time = 0

    @pattern_index += 1
    @pattern_index %= PATTERN_CLASSES.size

    add_pattern(@pattern_index)
  end

  def step_stage(dt)    
    advance_stage if !started_stages? || stage_expired?
    @stage_time += dt
  end

  def advance_stage
    @stage_index = (@stage_index + 1) % STAGES.size
    @stage_time = 0

    transition = STAGES[@stage_index][:transition]
    self.send(transition)
  end

  def started_stages?
    @stage_index >= 0
  end

  def stage_expired?
    duration = STAGES[@stage_index][:duration]
    @stage_time >= duration    
  end

  def step_fade(dt)
    @fade_time += dt if @fading
  end

  def render_output
    if @fading
      render_output_with_fade
    else
      render_output_without_fade
    end
  end

  def render_output_with_fade
    frac = @fade_time / FADE_DURATION
    frac = 1 if frac > 1

    pixels = (0...2).map do |i|
      @patterns[i].pixels
    end

    @output = (0...STRIP_COUNT).map do |n|
      (0...112).map do |i|
        p0 = pixels[0][n][i]
        p1 = pixels[1][n][i]

        #(0...3).map do |j|
        #  frac * p1[j] + (1 - frac) * p0[j]
        #end

        (0...3).map do |j|
          255.0 * (1 - (1 - p1[j] / 255.0) * (1 - (1 - frac) * p0[j] / 255.0))
        end        
      end
    end
  end

  def render_output_without_fade
    @output = @patterns[0].pixels
  end

  def send_output
    @client.set_pixels(@output.flatten)
  end

  def add_pattern(index)
    @patterns << PATTERN_CLASSES[index].new(STRIP_COUNT)
  end

  def remove_first_pattern
    return if @patterns.size == 1
    @patterns.shift
  end
end

Application.run!

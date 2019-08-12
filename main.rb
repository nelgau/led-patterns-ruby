require 'faderuby'
require 'rgb'

class Controller
  def initialize
    @colors = (0...64).map { RGB::Color.new(0, 0, 0) }
  end

  def step
    length = Random.rand(4..16)
    hue = Random.rand(720.0)

    low = Random.rand(0..56 - length)
    high = low + length

    hues = (0...64).map { |i| @colors[i].h }

    hf = 0.5

    (0...64).each do |i|
      neighbors = (1...6).map { |d| [i - d] }.flatten
      neighbors.select! { |n| n >= 0 && n < 64 }
      next if neighbors.empty?

      neighbor_hues = neighbors.map { |n| hues[n] }
      avg = neighbor_hues.inject(&:+) / neighbors.count.to_f
      @colors[i].h = hf * @colors[i].h + (1.0 - hf) * avg
    end 

    (0...64).each do |i|
      @colors[i].h = @colors[i].h + 5 
      @colors[i].darken_percent!(15)
    end

    (low...high).each do |i|
      f = (i - low).to_f / (high - low)
      l = 0.5 + 0.4 * Math.cos(Math::PI * (f - 0.5))
      color = RGB::Color.new(hue, 1.0, l)
      @colors[i] = color
    end
  end

  def pixels
    @colors.map(&:to_rgb)
  end
end

client = FadeRuby::Client.new('172.16.0.83', 7890)
controllers = (0..4).map { Controller.new }

loop do
  controllers.each(&:step)
  pixels = controllers.map(&:pixels)
  pixels = [pixels[0]] * 4
  client.set_pixels(pixels.flatten)

  sleep 1
end

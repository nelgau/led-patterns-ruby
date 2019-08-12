require 'faderuby'
require 'rgb'
require 'arcenciel'
require 'thread'

client = FadeRuby::Client.new('172.16.0.75', 7890)
mutex = Mutex.new

hue = 0
width = 0

center = 26

Thread.new do
  begin
    loop do
      mutex.synchronize do
        pixels = (0...64).map do |i|
          x = (i - center).abs
          ramp = width > 0 ? 1 - x / width : 0

          lightness = case
            when x < width
              0.5 * 0.25 + ramp
            when x < width + 1
              fraction = x - width - 1
              0.5 * fraction
            else
              0.0
            end

          RGB::Color.new(hue, 1.0, lightness).to_rgb
        end
        client.set_pixels(pixels.flatten)
      end

      sleep 0.025
    end
  rescue => e
    p e
  end
end


Arcenciel.run! do
  knob do
    name "Width"

    min 0
    max 32
    type :float
    sweep 540

    on_value do |w|
      mutex.synchronize do
        width = w
      end
    end
  end

  knob do
    name "Hue"

    min 0
    max 360
    type :float
    sweep 1440

    on_value do |h|
      mutex.synchronize do
        hue = h
      end
    end
  end
end

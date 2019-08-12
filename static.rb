require 'faderuby'
require 'rgb'

client = FadeRuby::Client.new('127.0.0.1', 7890)

k = 0
count = 112 * 8

loop do
  output = (0...count).map { [0, 0, 255] }
  client.set_pixels(output.flatten)

  sleep 0.1
  k += 1
end

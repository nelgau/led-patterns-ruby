require 'faderuby'
require 'rgb'
require 'arcenciel'
require 'thread'

client = FadeRuby::Client.new('172.16.0.75', 7890)
mutex = Mutex.new

u = (0...64).map { 0.0 }
v = (0...64).map { 0.0 }

du = 0.4
dv = 0.1
f = 0.014
k = 0.049

dt = 0.5
scale = 1

(0...64).each do |i|
  (!(i > 10 && i < 20) ? u : v)[i] = 0.5
end

Thread.new do
  loop do
    t = Random.rand(0...2)
    i = Random.rand(0...64)
    x = Random.rand(0.1)
    (t == 0 ? u : v)[i] += x

    grad2u = (0...64).map do |i|
      (u[(i - 1) % 64] - 2 * u[i] + u[(i + 1) % 64]) / 4.0
    end

    grad2v = (0...64).map do |i|
      (v[(i - 1) % 64] - 2 * v[i] + v[(i + 1) % 64]) / 4.0
    end

    (0...64).each do |i|
      u[i] += dt * (du * grad2u[i] - u[i] * v[i] * v[i] + f * (1 - u[i]))
      v[i] += dt * (dv * grad2v[i] + u[i] * v[i] * v[i] - (f + k) * v[i])
    end

    colors = (0...64).map do |i|
      RGB::Color.from_rgb(scale * 255 * u[i], scale * 255 * v[i], 0)
    end

    pixels = colors.map(&:to_rgb)
    client.set_pixels(pixels.flatten)

    sleep 0.025
  end
end

Arcenciel.run! do
  knob do
    name "F"

    min 0
    max 0.05
    type :float
    sweep 720

    on_value do |x|
      mutex.synchronize do
        f = x
      end
    end
  end

  knob do
    name "K"

    min 0
    max 0.05
    type :float
    sweep 720

    on_value do |x|
      mutex.synchronize do
        k = x
      end
    end
  end
end


class Pattern
  def initialize(strip_count)
    @strip_count = strip_count
    @controllers = (0...strip_count).map { |i| build_controller(i) }
  end

  def pixels
    @controllers.map(&:pixels)
  end

  def step(dt)
    @controllers.each { |c| c.step(dt) }
  end

  def halt!
    @controllers.each(&:halt!)
  end

  def build_controller(i)
    raise NotImplementedError
  end
end

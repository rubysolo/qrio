# track angle and distance between two Finder Patterns
class Qrio::Neighbor
  attr_accessor :source, :destination, :angle, :distance
  ANGLE  = Math::PI / 8
  ZERO   = 0..ANGLE
  NINETY = (ANGLE * 3)..(ANGLE * 5)
  ONEEIGHTY = (ANGLE * 7)..(ANGLE * 8)

  def initialize(source, destination)
    @source      = source
    @destination = destination

    dx = destination.center.first - source.center.first
    dy = destination.center.last  - source.center.last

    @angle    = Math.atan2(dy * -1, dx)
    @distance = Math.sqrt(dx ** 2 + dy ** 2)
  end

  def right_angle?
    ZERO.include?(angle.abs)      ||
    NINETY.include?(angle.abs)    ||
    ONEEIGHTY.include?(angle.abs)
  end
end

module Qrio
  # track angle and distance between two Finder Patterns
  class Neighbor
    attr_reader :source, :destination, :angle, :distance

    ANGLE     = Math::PI / 8
    ZERO      = 0..ANGLE
    NINETY    = (ANGLE * 3)..(ANGLE * 5)
    ONEEIGHTY = (ANGLE * 7)..(ANGLE * 8)

    def initialize(source, destination)
      @source      = source
      @destination = destination

			source.neighbors << self
			destination.neighbors << self

      dx = destination.center.first - source.center.first
      # images are top down, geometry is bottom up.  invert.
      dy = source.center.last - destination.center.last

      @angle    = Math.atan2(dy, dx)
      @distance = Math.sqrt(dx ** 2 + dy ** 2)
    end

    def to_coordinates
      [source.center, destination.center].flatten
    end

		def to_s
			"N#{ to_coordinates * ',' }"
		end

    def right_angle?
      ZERO.include?(angle.abs)      ||
      NINETY.include?(angle.abs)    ||
      ONEEIGHTY.include?(angle.abs)
    end
  end
end


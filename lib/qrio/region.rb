module Qrio
  # a rectangular matrix of bits
  class Region
    attr_reader :x1, :y1, :x2, :y2, :orientation

    def initialize(x1, y1, x2, y2)
      @x1 = x1
      @y1 = y1
      @x2 = x2
      @y2 = y2

      set_orientation
    end

    def left;   x1; end
    def right;  x2; end
    def top;    y1; end
    def bottom; y2; end

    def top_left
      [x1, y1]
    end

    def bottom_right
      [x2, y2]
    end

    def to_coordinates
      [top_left, bottom_right].flatten
    end

    def to_point_size
      [top_left, width, height].flatten
    end

    def to_s
      "R[#{ to_coordinates.join(',') }]"
    end

    def hash
      to_s.hash
    end

    def eql?(other)
      self == other
    end

    def ==(other)
      to_s == other.to_s
    end

    def width
      x2 - x1 + 1
    end

    def height
      y2 - y1 + 1
    end

    def center
      [left + width / 2, top + height / 2]
    end

    def horizontal?; orientation == :horizontal; end
    def vertical?;   orientation == :vertical;   end

    def orientation_matches?(other)
      orientation == other.orientation
    end

    def union(other)
      self.class.new(
        [left,   other.left].min,
        [top,    other.top].min,
        [right,  other.right].max,
        [bottom, other.bottom].max
      )
    end

    def translate(xoffset, yoffset)
      self.class.new(
        left   - xoffset,
        top    - yoffset,
        right  - xoffset,
        bottom - yoffset
      )
    end

    private

    def set_orientation
      @orientation = case
      when width > height
        :horizontal
      when height > width
        :vertical
      else
        :square
      end
    end
  end
end

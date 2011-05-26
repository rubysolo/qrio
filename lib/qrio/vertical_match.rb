module Qrio
  class VerticalMatch < FinderPatternSlice
    def self.build(offset, origin, terminus)
      new(offset, origin, offset, terminus)
    end

    def offset;   left;   end
    def origin;   top;    end
    def terminus; bottom; end

    def length
      height
    end

    def breadth
      width
    end

    def left_of?(other)
      right < other.left
    end

    def right_of?(other)
      left > other.right
    end

    def offset_diff(other)
      left_of?(other) ? other.left - right : left - other.right
    end
  end
end

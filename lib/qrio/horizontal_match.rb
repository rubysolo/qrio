module Qrio
  class HorizontalMatch < FinderPatternSlice
    def self.build(offset, origin, terminus)
      new(origin, offset, terminus, offset)
    end

    def offset;   top;   end
    def origin;   left;  end
    def terminus; right; end

    def length
      width
    end

    def breadth
      height
    end

    def above?(other)
      other.top > bottom
    end

    def below?(other)
      other.bottom < top
    end

    def offset_diff(other)
      above?(other) ? other.top - bottom : top - other.bottom
    end
  end
end

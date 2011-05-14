#######
#     #
# ### #
# ### #
# ### #
#     #
#######

# This class is responsible for locating finder patterns in
# a bitmap.  The QR finder pattern is a solid square of black
# pixels surrounded by an outline of white pixels, surrounded by 
# an outline of black pixels.  Each outer border should be about
# the same width, and the inner square should be 3 times as wide.

class Qrio::FinderPattern
  RATIO = [1,1,3,1,1] # any horizontal or vertical slice should have pixels in this ratio

  # a horizontal or vertical slice of a finder pattern
  class Slice
    MAX_EDGE_DIFF   = 1
    MAX_OFFSET_DIFF = 2

    attr_accessor :x1, :y1, :x2, :y2, :orientation

    def initialize(x1, y1, x2, y2)
      self.x1 = x1
      self.y1 = y1
      self.x2 = x2
      self.y2 = y2

      self.orientation = case
      when width > height
        :horizontal
      when height > width
        :vertical
      else
        nil
      end
    end

    def horizontal?; orientation == :horizontal; end
    def vertical?;   orientation == :vertical;   end

    def left;        [x1, y1];     end
    def right;       [x2, y2];     end
    def left_edge;   left.first;   end
    def right_edge;  right.first;  end

    def top;         [x1, y1];     end
    def bottom;      [x2, y2];     end
    def top_edge;    top.last;     end
    def bottom_edge; bottom.last;  end

    def height; bottom_edge - top_edge + 1; end
    def width;  right_edge - left_edge + 1; end

    def center
      [left + width/2.0, top + height/2.0]
    end

    # number of pixels down from top for horizontal slices,
    # number of pixels right from left for vertical slices
    def offset
      horizontal? ? left.last : top.first
    end

    # detect if we are looking at horizontal and vertical slices of the
    # same finder pattern
    def intersects?(other_slice)
      return false if other_slice.orientation == orientation
      if horizontal?
        left_edge <= other_slice.left_edge && right_edge >= other_slice.right_edge &&
        top_edge  >= other_slice.top_edge && bottom_edge <= other_slice.bottom_edge
      else
        left_edge >= other_slice.left_edge && right_edge <= other_slice.right_edge &&
        top_edge  <= other_slice.top_edge && bottom_edge >= other_slice.bottom_edge
      end
    end

    # if edges are within 1 of our edge, and offset with 2 of our offset
    # then we're adjacent
    def adjacent?(other_slice)
      if horizontal?
        left_edges_match?(other_slice) &&
        right_edges_match?(other_slice) &&
        within_offset_range?(other_slice)
      else
        top_edges_match?(other_slice) &&
        bottom_edges_match?(other_slice) &&
        within_offset_range?(other_slice)
      end
    end

    def left_edges_match?(other_slice)
      (other_slice.left_edge - left_edge).abs <= MAX_EDGE_DIFF
    end

    def right_edges_match?(other_slice)
      (other_slice.right_edge - right_edge).abs <= MAX_EDGE_DIFF
    end

    def top_edges_match?(other_slice)
      (other_slice.top_edge - top_edge).abs <= MAX_EDGE_DIFF
    end

    def bottom_edges_match?(other_slice)
      (other_slice.bottom_edge - bottom_edge).abs <= MAX_EDGE_DIFF
    end

    def within_offset_range?(other_slice)
      if horizontal?
        ((other_slice.bottom_edge - top_edge).abs <= MAX_OFFSET_DIFF) ||
        ((other_slice.top_edge - bottom_edge).abs <= MAX_OFFSET_DIFF)
      else
        ((other_slice.right_edge - left_edge).abs <= MAX_OFFSET_DIFF) ||
        ((other_slice.left_edge - right_edge).abs <= MAX_OFFSET_DIFF)
      end
    end

    # join adjacent slices together into a single thicker slice
    def union(other_slice)
      top    = [top_edge, other_slice.top_edge].min
      bottom = [bottom_edge, other_slice.bottom_edge].max
      left   = [left_edge, other_slice.left_edge].min
      right  = [right_edge, other_slice.right_edge].max

      Slice.new(left, top, right, bottom)
    end
  end

  class << self
    # given a raw bitmap, extract finder patterns
    def extract(bitmap)
      candidates = find_candidates(bitmap)
    end

    def find_candidates(bitmap)
      hmatches = []
      vmatches = []
      buffer   = [0]
      previous = false

      bitmap.rows.each_with_index do |row, y|
        row.pixels.each_with_index do |pixel, x|
          if match_pixel(previous, pixel, x, y, buffer)
            hmatches << Slice.new(x - buffer.sum, y, x, y)
          end
        end
      end
      hmatches = group_adjacent(hmatches)

      bitmap.columns.each_with_index do |column, x|
        column.pixels.each_with_index do |pixel, y|
          if match_pixel(previous, pixel, x, y, buffer)
            vmatches << Slice.new(x, y - buffer.sum, x, y)
          end
        end
      end
      vmatches = group_adjacent(vmatches)

      find_intersections(hmatches, vmatches)
    end

    # adjacent row/column slices of (close to) the same length/width
    # can be combined into one rectangle
    def group_adjacent(slices)
      grouped = []

      slices.each do |slice|
        if grouped.empty?
          grouped << slice
        else
          grouped.each_with_index do |g, index|
            grouped[index] = g.union(slice) if g.adjacent?(slice)
          end
        end
      end

      grouped
    end

    def find_intersections(horizontal, vertical)
      intersections = []

      horizontal.each do |h|
        vertical.each do |v|
          intersections << h.union(v) if h.intersects?(v)
        end
      end

      intersections
    end

    # test intersection of two line segments
    def intersects?(h, v)
      lx, ly, rx, ry = *h
      tx, ty, bx, by = *v

      # x from vertical is in horizontal range and y from horizontal is in vertical range
      lx <= tx && tx <= rx &&
      ty <= ly && ly <= by
    end

    def match_pixel(previous, pixel, x, y, buffer, mode)
      if pixel == previous
        # one more pixel just like the last, increment length
        buffer.last += 1
        return false
      else
        # transition
        buffer << 1
        buffer.shift while buffer.length > 5
        previous = pixel

        matches_finder_pattern?(buffer)
      end
    end

    def matches_finder_pattern?(widths)
      return false if widths.length < 5
      baseline = widths.first
      widths.map{|w| (w.to_f / baseline.to_f).round } == RATIO
    end
  end
end

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
  DEBUG_MODE = true

  # a horizontal or vertical slice of a finder pattern
  class Slice
    MAX_SLICE_WIDTH_DIFF  = 0.05
    MAX_SLICE_LENGTH_DIFF = 0.1
    MAX_EDGE_DIFF         = 1
    MAX_OFFSET_DIFF       = 2

    attr_accessor :x1, :y1, :x2, :y2, :orientation

    def initialize(x1, y1, x2, y2)
      @x1 = x1
      @y1 = y1
      @x2 = x2
      @y2 = y2

      @orientation = case
      when width > height
        :horizontal
      when height > width
        :vertical
      else
        nil
      end
    end

    def to_s
      "#{ orientation } : (#{ (horizontal? ? left : top) * ',' }) -> (#{ (horizontal? ? right : bottom) * ','}) [#{ width }x#{ height }]"
    end

    def draw_debug(gc)
      gc.line left_edge,  top_edge,    right_edge, top_edge
      gc.line right_edge, top_edge,    right_edge, bottom_edge
      gc.line right_edge, bottom_edge, left_edge,  bottom_edge
      gc.line left_edge,  bottom_edge, left_edge,  top_edge
    end

    def to_a
      [x1, y1, x2, y2]
    end

    def <=>(other)
      to_a <=> other.to_a
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
      [left_edge + width/2.0, top_edge + height/2.0]
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
        top_edge  >= other_slice.top_edge && bottom_edge <= other_slice.bottom_edge &&
        ((height - other_slice.width).abs / height.to_f) < MAX_SLICE_WIDTH_DIFF &&
        ((width - other_slice.height).abs / width.to_f) < MAX_SLICE_LENGTH_DIFF
      else
        left_edge >= other_slice.left_edge && right_edge <= other_slice.right_edge &&
        top_edge  <= other_slice.top_edge && bottom_edge >= other_slice.bottom_edge
        ((width - other_slice.height).abs / width.to_f) < MAX_SLICE_WIDTH_DIFF &&
        ((height - other_slice.width).abs / height.to_f) < MAX_SLICE_LENGTH_DIFF
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
      top    = [top_edge,    other_slice.top_edge].min
      bottom = [bottom_edge, other_slice.bottom_edge].max
      left   = [left_edge,   other_slice.left_edge].min
      right  = [right_edge,  other_slice.right_edge].max

      Slice.new(left, top, right, bottom)
    end
  end

  class << self
    # given a raw bitmap, extract finder patterns
    def extract(bitmap)
      candidates = find_candidates(bitmap)
    end

    def find_candidates(bitmap)
      debug_mode do
        @gc = Magick::Draw.new
        @gc.stroke_width 1
      end

      hmatches = []
      vmatches = []
      previous = false

      rows = bitmap.rows
      columns = bitmap.columns

      rows.times do |y|
        buffer = []
        columns.times do |x|
          pixel = bitmap.get_pixels(x, y, 1, 1).first

          this_matches, previous = match_pixel(previous, pixel, buffer)
          if this_matches
            total_width = buffer.inject(0){|a,i| a += i }
            hmatches << Slice.new(x - total_width, y, x, y)
          end
        end
      end
      hmatches = group_adjacent(hmatches)
      debug_mode do
        @gc.stroke 'blue'
        hmatches.each{|h| h.draw_debug(@gc) }
      end

      columns.times do |x|
        buffer = []
        rows.times do |y|
          pixel = bitmap.get_pixels(x, y, 1, 1).first

          this_matches, previous = match_pixel(previous, pixel, buffer)
          if this_matches
            total_height = buffer.inject(0){|a,i| a += i }
            vmatches << Slice.new(x, y - total_height, x, y)
          end
        end
      end
      vmatches = group_adjacent(vmatches)
      debug_mode do
        @gc.stroke 'green'
        vmatches.each{|v| v.draw_debug(@gc) }
      end

      intersections = find_intersections(hmatches, vmatches)

      if DEBUG_MODE
        @gc.stroke 'red'
        @gc.stroke_width 1

        intersections.each {|i| i.draw_debug(@gc) }

        @gc.draw bitmap
        bitmap.write 'debug.png'
      end

      intersections
    end

    # adjacent row/column slices of (close to) the same length/width
    # can be combined into one rectangle
    def group_adjacent(slices)
      grouped = []

      slices.sort.each do |slice|
        if grouped.empty?
          grouped << slice
        else
          added = false

          grouped.each_with_index do |g, index|
            if g.adjacent?(slice)
              added = true
              grouped[index] = g.union(slice)
            end
          end

          grouped << slice unless added
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

    def match_pixel(previous, pixel, buffer)
      pixel = pixel.to_color == "black"

      if pixel === previous
        # one more pixel just like the last, increment length
        run_length = buffer.pop || 0
        buffer << run_length + 1
        return [false, pixel]
      else
        # transition
        found_match = matches_finder_pattern?(buffer)

        buffer << 1
        buffer.shift while buffer.length > 5

        [found_match, pixel]
      end
    end

    def matches_finder_pattern?(widths)
      return false if widths.length < 5

      baseline = widths.first
      widths.map{|w| (w.to_f / baseline.to_f).round } == RATIO
    end

    def debug_mode
      yield if DEBUG_MODE
    end
  end
end

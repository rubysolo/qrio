# a horizontal or vertical slice of a finder pattern
class Qrio::Slice
  MAX_SLICE_WIDTH_DIFF  = 0.15
  MAX_SLICE_LENGTH_DIFF = 0.35
  MAX_EDGE_DIFF         = 0.05
  MAX_OFFSET_DIFF       = 0.25

  attr_accessor :x1, :y1, :x2, :y2, :orientation, :neighbors

  def initialize(x1, y1, x2, y2)
    @x1 = x1
    @y1 = y1
    @x2 = x2
    @y2 = y2
    @neighbors = []

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

  def to_a(invert=false)
    invert ? [y1, x1, y2, x2] : [x1, y1, x2, y2]
  end

  def <=>(other)
    to_a(horizontal?) <=> other.to_a(horizontal?)
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

  def long_side
    horizontal? ? width : height
  end

  def short_side
    horizontal? ? height : width
  end

  def ratio
    short_side.to_f / long_side.to_f
  end

  # the ideal grouped slice should have short side to long side ratio of 3/7
  def has_correct_ratio?
    (0.25..0.59).include? ratio
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
    (other_slice.left_edge - left_edge).abs / long_side.to_f <= MAX_EDGE_DIFF
  end

  def right_edges_match?(other_slice)
    (other_slice.right_edge - right_edge).abs / long_side.to_f <= MAX_EDGE_DIFF
  end

  def top_edges_match?(other_slice)
    (other_slice.top_edge - top_edge).abs / long_side.to_f <= MAX_EDGE_DIFF
  end

  def bottom_edges_match?(other_slice)
    (other_slice.bottom_edge - bottom_edge).abs / long_side.to_f <= MAX_EDGE_DIFF
  end

  def within_offset_range?(other_slice)
    offset_ranges(other_slice).any?{|r| r <= MAX_OFFSET_DIFF }
  end

  def offset_ranges(other_slice)
    if horizontal?
      [
        (other_slice.bottom_edge - top_edge).abs / long_side.to_f,
        (other_slice.top_edge - bottom_edge).abs / long_side.to_f
      ]
    else
      [
        (other_slice.right_edge - left_edge).abs / long_side.to_f,
        (other_slice.left_edge - right_edge).abs / long_side.to_f
      ]
    end
  end

  # join adjacent slices together into a single thicker slice
  def union(other_slice)
    top    = [top_edge,    other_slice.top_edge].min
    bottom = [bottom_edge, other_slice.bottom_edge].max
    left   = [left_edge,   other_slice.left_edge].min
    right  = [right_edge,  other_slice.right_edge].max

    Qrio::Slice.new(left, top, right, bottom)
  end

  # given a list of other slices, calculate the angle and distance to each
  def add_neighbors(slices)
    slices.each do |s|
      @neighbors << Qrio::Neighbor.new(self, s) unless center == s.center
    end
  end
end

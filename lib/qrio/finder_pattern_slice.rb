module Qrio
  # QR codes have a finder pattern in three corners.  any horizontal or
  # vertical slice through the center square will be a band of:
  # black, white, black, white, black, with widths matching ratio:
  # 1, 1, 3, 1, 1.  According to spec, the tolerance should be +/- 0.5.
  class FinderPatternSlice < Region
    ONE   = 0.5..1.5
    THREE = 2.1..3.9 # not to spec, but required for some "in-the-wild" QR

    ENDPOINT_TOLERANCE = 0.05 # drift of origin and terminus between adjacent slices
    OFFSET_TOLERANCE   = 0.25 # how many non-matching slices can be skipped?

    LENGTH_TOLERANCE = 0.35 # allowed length difference bewteen 2 intersecting slices
    WIDTH_TOLERANCE  = 0.15 # allowed width difference bewteen 2 intersecting slices

    attr_accessor :neighbors
    attr_reader :offset, :origin, :terminus

    def initialize(*args)
      @neighbors = []
      super
    end

    def to_s
      "#{ self.class.to_s.gsub(/^.*::/,'')[0,1] }#{ offset }(#{ origin }->#{ terminus })"
    end

    def aspect_ratio
      breadth / length.to_f
    end

    # based on the 1, 1, 3, 1, 1 width ratio, a finder pattern has total
    # width of 7.  an ideal grouped slice would then have aspect ratio
    # of 3/7, since slice breadth would be 3 (just the center square)
    # and length would be 7 (entire slice)
    def matches_aspect_ratio?
      (0.25..0.59).include? aspect_ratio
    end
    

    class << self
      # given a width buffer extracted from a given coordinate, test
      # for ratio matching.  if it matches, return a match object of
      # the appropriate orientation
      def build_matching(offset, origin, widths, direction)
        return nil unless matches_ratio?(widths)

        match_class = direction == :horizontal ? HorizontalMatch : VerticalMatch
        terminus = origin + widths.inject(0){|s,w| s + w } - 1

        match_class.build(offset, origin, terminus)
      end

      def matches_ratio?(widths)
        norm = normalized_ratio(widths)

        ONE.include?(norm[0]) &&
        ONE.include?(norm[1]) &&
        THREE.include?(norm[2]) &&
        ONE.include?(norm[3]) &&
        ONE.include?(norm[4])
      end

      def normalized_ratio(widths)
        scale = (widths[0] + widths[1] + widths[3] + widths[4]) / 4.0
        widths.map{|w| w / scale }
      end
    end

    def <=>(other)
      return -1 if offset < other.offset
      return  1 if offset > other.offset
      origin <=> other.origin
    end

    def intersects?(other)
      ! orientation_matches?(other) &&
      (other.origin..other.terminus).include?(offset) &&
      (origin..terminus).include?(other.offset) &&
      length_matches?(other) &&
      width_matches?(other)
    end

    def adjacent?(other)
      endpoints_match?(other) && offset_matches?(other)
    end

    def endpoints_match?(other)
      origin_matches?(other) && terminus_matches?(other)
    end

    def origin_diff(other)
      (origin - other.origin).abs / length.to_f
    end

    def origin_matches?(other)
      origin_diff(other) <= ENDPOINT_TOLERANCE
    end

    def terminus_diff(other)
      (terminus - other.terminus).abs / length.to_f
    end

    def terminus_matches?(other)
      terminus_diff(other) <= ENDPOINT_TOLERANCE
    end

    def normalized_offset_diff(other)
      offset_diff(other) / length.to_f
    end

    def offset_matches?(other)
      normalized_offset_diff(other) <= OFFSET_TOLERANCE
    end

    def length_diff(other)
      (length - other.length).abs / length.to_f
    end

    def length_matches?(other)
      length_diff(other) <= LENGTH_TOLERANCE
    end

    def width_diff(other)
      (width - other.width).abs / length.to_f
    end

    def width_matches?(other)
      width_diff(other) <= WIDTH_TOLERANCE
    end
  end
end

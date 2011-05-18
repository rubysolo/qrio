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
  # any horizontal or vertical slice should have pixels with ratio 1,1,3,1,1
  # we allow some slop around those values
  RATIO = [
    0.70..1.30,
    0.70..1.30,
    2.10..3.90,
    0.70..1.30,
    0.70..1.30
  ]
  DEBUG_MODE = true

  class << self
    # given a raw bitmap, extract finder patterns
    def extract(bitmap)
      candidates = find_candidates(bitmap)

      debug_mode do
        @gc.stroke 'red'
        @gc.stroke_width 1
        candidates.each {|i| i.draw_debug(@gc) }
      end

      if candidates.length >= 3
        # force common orientation for sorting to work correctly
        candidates.each{|c| c.orientation = :vertical }
        candidates = candidates.sort

        candidates.each do |c|
          c.add_neighbors candidates
        end

        shared_corners = candidates.select do |c|
          c.neighbors.select{|n| n.right_angle? }.count > 1
        end

        if shared_corner = shared_corners.first
          # TODO : what about multiple candidates?
          debug_mode do
            @gc.stroke 'cyan'
            shared_corner.neighbors.each do |n|
              @gc.line *n.coordinates
            end
          end

          bounds = shared_corner
          shared_corner.neighbors.select{|n| n.right_angle? }.each do |n|
            bounds = bounds.union(n.destination)
          end

          debug_mode do
            @gc.draw bitmap
            finder_pattern = bitmap.crop(bounds.left_edge, bounds.top_edge, bounds.width, bounds.height)
            finder_pattern.write 'debug.png'
          end
        else
          puts "no shared corner!"
        end

        # TODO : rotate, transform
      end


      candidates
    end

    def find_candidates(bitmap)
      debug_mode do
        @gc = Magick::Draw.new
        @gc.stroke_width 1
      end

      hmatches = find_matches(bitmap, :horizontal)
      vmatches = find_matches(bitmap, :vertical)
      intersections = find_intersections(hmatches, vmatches)


      intersections
    end

    def find_matches(bitmap, direction)
      outer, inner = bitmap.rows, bitmap.columns
      outer, inner = inner, outer if direction == :vertical

      matches = []
      previous = false

      outer.times do |o|
        buffer = []
        inner.times do |i|
          x, y = i, o
          x, y = y, x if direction == :vertical

          pixel = bitmap.get_pixels(x, y, 1, 1).first

          matched_width, previous = match_pixel(previous, pixel, buffer)
          if matched_width > 0
            if direction == :vertical
              matches << Qrio::Slice.new(x, y - matched_width, x, y)
            else
              matches << Qrio::Slice.new(x - matched_width, y, x, y)
            end
          end
        end
      end

      matches = group_adjacent(matches)
      matches = matches.select(&:has_correct_ratio?)

      debug_mode do
        @gc ||= Magick::Draw.new
        @gc.stroke(direction == :vertical ? 'green' : 'blue')
        matches.each{|h| h.draw_debug(@gc) }
      end

      matches
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
        return [0, pixel]
      else
        # transition
        matched_width = 0
        if matches_finder_pattern?(buffer)
          matched_width = buffer.inject(0){|sum,w| sum + w }
        end

        buffer << 1
        buffer.shift while buffer.length > 5

        [matched_width, pixel]
      end
    end

    def matches_finder_pattern?(widths)
      return false if widths.length < 5

      RATIO.zip(normalized_ratio(widths)).all? do |range, value|
        range.include? value
      end
    end

    def normalized_ratio(widths)
      scale = 0
      widths.each_with_index{|w,i| scale += w unless i == 2 }
      scale /= 4.0

      widths.map{|w| w / scale }
    end

    def debug_mode
      yield if DEBUG_MODE
    end
  end
end

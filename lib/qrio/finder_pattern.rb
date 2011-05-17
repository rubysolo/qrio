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
    0.75..1.25,
    0.75..1.25,
    2.10..3.90,
    0.75..1.25,
    0.75..1.25
  ]
  DEBUG_MODE = true

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
            hmatches << Qrio::Slice.new(x - total_width, y, x, y)
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
            vmatches << Qrio::Slice.new(x, y - total_height, x, y)
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

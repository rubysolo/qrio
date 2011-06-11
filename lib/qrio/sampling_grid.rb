module Qrio
  class SamplingGrid
    attr_reader :origin_corner, :top_right, :bottom_left,
                :orientation, :bounds, :angles,
                :block_width, :block_height, :provisional_version,
                :finder_patterns, :matrix

    def initialize(matrix, finder_patterns)
      @matrix          = matrix
      @finder_patterns = finder_patterns
      @angles          = []

      find_origin_corner
      detect_orientation
    end

    def find_origin_corner(normalized=false)
      build_finder_pattern_neighbors

      shared_corners = @finder_patterns.select do |fp|
        fp.neighbors.select(&:right_angle?).count > 1
      end

      # TODO : handle multiple possible matches
      if @origin_corner = shared_corners.first
        if normalized
          # we have correct orientation, identify fp positions
          @top_right = non_origin_finder_patterns.map(&:destination).detect{|fp| fp.center.last < @matrix.height / 2.0 }
          @bottom_left = non_origin_finder_patterns.map(&:destination).detect{|fp| fp.center.first < @matrix.width / 2.0 }
        else
          set_bounds
        end
      end
    end

    def set_bounds
      @bounds = @origin_corner.dup
      @bounds.neighbors.select(&:right_angle?).each do |n|
        @bounds = @bounds.union(n.destination)
      end
    end

    # which way is the QR rotated?
    #   0) normal - shared finder patterns in top left
    #   1)        - shared finder patterns in top right
    #   2)        - shared finder patterns in bottom right
    #   3)        - shared finder patterns in bottom left
    def detect_orientation
      # TODO : handle multiple possible matches
      other_corners = non_origin_finder_patterns

      dc = other_corners.map(&:distance).inject(0){|s,d| s + d } / 2.0
      threshold = dc / 2.0

      other_corners = other_corners.map(&:destination)

      set_block_dimensions(@origin_corner, *other_corners)
      @provisional_version = ((dc / @block_width).round - 10) / 4

      xs = other_corners.map{|fp| fp.center.first }
      ys = other_corners.map{|fp| fp.center.last }

      above = ys.select{|y| y < (@origin_corner.center.last - threshold) }
      left  = xs.select{|x| x < (@origin_corner.center.first - threshold) }

      @orientation = if above.any?
        left.any? ? 2 : 3
      else
        left.any? ? 1 : 0
      end
    end

    def non_origin_finder_patterns
      @origin_corner.neighbors.select(&:right_angle?)[0,2]
    end

    def build_finder_pattern_neighbors
      @finder_patterns.each do |source|
        @finder_patterns.each do |destination|
          next if source.center == destination.center
          @angles << Neighbor.new(source, destination)
        end
      end
    end

    def set_block_dimensions(*finder_patterns)
      @block_width  = finder_patterns.inject(0){|s,f| s + f.width } / 21.0
      @block_height = finder_patterns.inject(0){|s,f| s + f.height } / 21.0
    end

    def logical_width
      @matrix.width / @block_width
    end

    def logical_height
      @matrix.height / @block_height
    end

    def normalize
      @matrix = @matrix.extract(*@bounds.to_point_size)
      translate(*@bounds.top_left)

      if @orientation > 0
        (4 - @orientation).times do
          rotate
        end
      end

      find_origin_corner(true)
    end

    def translate(x, y)
      @angles = []
      other_corners = non_origin_finder_patterns.map(&:destination)

      @origin_corner = @origin_corner.translate(x, y)
      translated = [@origin_corner]
      translated += other_corners.map{|c| c.translate(x, y) }

      @finder_patterns = translated
    end

    def rotate
      @matrix = @matrix.rotate
      @finder_patterns.map!{|f| f.rotate(@bounds.width, @bounds.height) }
    end

    def extracted_pixels
      start_x = @origin_corner.center.first - (@block_width  * 3.0)
      start_y = @origin_corner.center.last  - (@block_height * 3.0)

      dest_x = @bottom_left.center.first - (@block_width * 3.0)
      dest_y = @top_right.center.last  - (@block_height * 3.0)

      # TODO : take bottom right alignment pattern into consideration
      dy = (dest_y - start_y) / logical_width
      dx = (dest_x - start_x) / logical_height

      logical_height.round.times do |row_index|
        row_start_x = start_x + row_index * dx
        row_start_y = start_y + (row_index * @block_height)

        logical_width.round.times do |col_index|
          x = row_start_x + (col_index * @block_width)
          y = row_start_y + (col_index * dy)

          yield x.round, y.round
        end
      end
    end
  end
end

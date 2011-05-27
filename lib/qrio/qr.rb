module Qrio
  class Qr
    attr_reader :candidates, :matches, :finder_patterns, :qr_bounds

    def initialize
      initialize_storage
    end

    def self.load(filename)
      instance = new
      instance.load_image(filename)

      instance.scan(:horizontal)
      instance.scan(:vertical)

      instance.filter_candidates
      instance.find_intersections
      instance.set_qr_bounds

      # TODO : decode and set decoded flag
      instance
    end

    def load_image(filename)
      initialize_storage

      image_type = File.extname(filename).upcase.gsub('.', '')
      image_loader_class = "#{ image_type }ImageLoader"
      image_loader_class = ImageLoader.const_get(image_loader_class) rescue nil

      if image_loader_class.nil?
        raise "Image type '#{ image_type }' not supported"
      end

      @matrix = image_loader_class.load(filename)
    end

    def save_image(filename, options={})
      png = ChunkyPNG::Image.new(
        @matrix.width,
        @matrix.height,
        ChunkyPNG::Color::WHITE
      )

      (0..(@matrix.width - 1)).to_a.each do |x|
        (0..(@matrix.height - 1)).to_a.each do |y|
          png[x, y] = ChunkyPNG::Color::BLACK if @matrix[x, y]
        end
      end

      if options[:annotate].include?(:candidates)
        @candidates[:horizontal].each do |hmatch|
          png.rect(*hmatch.to_coordinates, color(:green))
        end

        @candidates[:vertical].each do |vmatch|
          png.rect(*vmatch.to_coordinates, color(:magenta))
        end
      end

      if options[:annotate].include?(:matches)
        @matches[:horizontal].each do |hmatch|
          png.rect(*hmatch.to_coordinates, color(:green))
        end

        @matches[:vertical].each do |vmatch|
          png.rect(*vmatch.to_coordinates, color(:magenta))
        end
      end

      if options[:annotate].include?(:finder_patterns)
        @finder_patterns.each do |finder_pattern|
          png.rect(*finder_pattern.to_coordinates, color(:red))
        end
      end

      if options[:annotate].include?(:angles)
        @neighbors[0,100].each do |neighbor|
          png.line_xiaolin_wu(*neighbor.to_coordinates, color(:cyan))
        end
      end

      png = png.crop(*@qr_bounds.to_point_size) if options[:crop]
      png.save(filename, :fast_rgba)
    end

    def color(name)
      rgb = {
        :green   => [  0, 255,   0],
        :red     => [255,   0,   0],
        :magenta => [227,  91, 216],
        :cyan    => [  0, 255, 255],
      }[name]

      ChunkyPNG::Color.rgb(*rgb)
    end

    def scan(direction)
      vectors = direction == :horizontal ? @matrix.rows : @matrix.columns
      vectors.each_with_index do |vector, offset|
        pattern = rle(vector)

        if pattern.length >= 5
          origin = 0
          segment = pattern.slice!(0,4)

          while next_length = pattern.shift
            segment << next_length

            if candidate = find_candidate(offset, origin, segment, direction)
              add_candidate(candidate, direction)
            end

            origin += segment.shift
          end
        end
      end
    end

    def find_candidate(offset, origin, segment, direction)
      FinderPatternSlice.build_matching(offset, origin, segment, direction)
    end

    def add_candidate(new_candidate, direction)
      added = false

      @candidates[direction].each_with_index do |existing, index|
        if new_candidate.adjacent?(existing)
          @candidates[direction][index] = existing.union(new_candidate)
          added = true
        end
      end

      @candidates[direction] << new_candidate unless added
    end

    def filter_candidates
      [:horizontal, :vertical].each do |direction|
        @candidates[direction].uniq.each do |candidate|
          @matches[direction] << candidate if candidate.matches_aspect_ratio?
        end
      end
    end

    # transform a vector of bits in to a run-length encoded vector of widths
    # example:  [1, 1, 1, 1, 0, 0, 1, 1, 1] => [4, 2, 3]
    def rle(vector)
      v = vector.dup

      pattern = []
      length = 1
      last = v.shift

      v.each do |current|
        if current === last
          length += 1
        else
          pattern << length
          length = 1
          last = current
        end
      end

      pattern << length
    end

    # find intersections of horizontal and vertical slices, these
    # are (likely) finder patterns
    def find_intersections
      @matches[:horizontal].each do |h|
        @matches[:vertical].each do |v|
          @finder_patterns << h.union(v) if h.intersects?(v)
        end
      end
    end

    def set_qr_bounds
      if @finder_patterns.length >= 3
        build_finder_pattern_neighbors

        shared_corners = @finder_patterns.select do |fp|
          fp.neighbors.select(&:right_angle?).count > 1
        end

        # TODO : handle multiple possible matches
        if @qr_bounds = shared_corners.first
          @qr_bounds.neighbors.select(&:right_angle?).each do |n|
            @qr_bounds = @qr_bounds.union(n.destination)
          end
        end
      end
    end

    def build_finder_pattern_neighbors
      @finder_patterns.each do |source|
        @finder_patterns.each do |destination|
          next if source.center == destination.center
          @neighbors << Neighbor.new(source, destination)
        end
      end
    end

    private

    def initialize_storage
      @candidates = {
        :horizontal => [],
        :vertical   => [],
      }
      @matches = {
        :horizontal => [],
        :vertical   => [],
      }
      @finder_patterns = []
      @neighbors = []
    end
  end

  def self.decode(filename)
    qr = Qr.load(filename)
    qr.decoded? ? qr.text : qr
  end
end

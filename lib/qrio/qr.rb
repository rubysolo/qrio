module Qrio
  class Qr
    attr_reader :candidates, :matches, :finder_patterns, :qr_bounds
    include ImageDumper

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

      instance.build_normalized_qr

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

      @input_matrix = image_loader_class.load(filename)
    end

    def scan(direction)
      vectors = direction == :horizontal ? @input_matrix.rows : @input_matrix.columns
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
        @sampling_grid = SamplingGrid.new(@input_matrix, @finder_patterns)
        @qr_bounds = @sampling_grid.bounds
      end
    end

    # extract the qr into a smaller matrix and rotate to standard orientation
    def build_normalized_qr
      return false if @sampling_grid.nil?

      original_orientation = @sampling_grid.orientation

      @sampling_grid.normalize
      @extracted_matrix = @sampling_grid.matrix

      @translated_matches = {
        :horizontal => [],
        :vertical   => []
      }
      @translated_finder_patterns = []
      @translated_neighbors = []

      @matches[:horizontal].each do |m|
        m = m.translate(*@qr_bounds.top_left)
        if original_orientation > 0
          (4 - original_orientation).times do
            m = m.rotate(@qr_bounds.width, @qr_bounds.height)
          end
        end
        @translated_matches[:horizontal] << m
      end

      @matches[:vertical].each do |m|
        m = m.translate(*@qr_bounds.top_left)
        if original_orientation > 0
          (4 - original_orientation).times do
            m = m.rotate(@qr_bounds.width, @qr_bounds.height)
          end
        end
        @translated_matches[:vertical] << m
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
      @input_matrix = @extracted_matrix = nil
    end
  end

  def self.decode(filename)
    qr = Qr.load(filename)
    qr.decoded? ? qr.text : qr
  end
end

module Qrio
  class QrMatrix < Matrix
    FORMAT_MASK = 0b101_0100_0001_0010
    ERROR_CORRECTION_LEVEL = %w( M L H Q )

    def error_correction_level
      ERROR_CORRECTION_LEVEL[read_format[:error_correction]]
    end

    def blocks
      @blocks = []
      @block  = []

      (0..(width - 3)).step(2) do |bcol|
        bcol = width - 1 - bcol
        scanning_up = ((bcol / 2) % 2) == 0
        bcol -= 1 if bcol <= 6

        (0..(height - 1)).each do |brow|
          brow = height - 1 - brow if scanning_up

          add_bit(bcol, brow)
          add_bit(bcol - 1, brow)
        end
      end

      @blocks
    end

    def add_bit(x, y)
      if data_or_correction?(x, y)
        @block.push self[x, y]

        if @block.length == 8
          @blocks << @block.map{|b| b ? '1' : '0' }.join.to_i(2)
          @block = []
        end
      end
    end

    def data_or_correction?(x, y)
      ! in_finder_pattern?(x, y)    &&
      ! in_alignment_pattern?(x, y) &&
      ! in_alignment_line?(x, y)
    end

    def in_finder_pattern?(x, y)
      (x < 9           && y < 9) ||
      (x > (width - 9) && y < 9) ||
      (x < 9           && y > (height - 9))
    end

    def in_alignment_pattern?(x, y)
      ((width  - 9)..(width  - 5)).include?(x) &&
      ((height - 9)..(height - 5)).include?(y)
    end

    def in_alignment_line?(x, y)
      (x == 6) || (y == 6)
    end

    private

    def read_format
      @format ||= begin
        bits = 0

        0.upto(5) do |row_idx|
          bits = bits << 1
          bits += 1 if self[8, row_idx]
        end

        bits = bits << 1
        bits += 1 if self[8, 7]
        bits = bits << 1
        bits += 1 if self[8, 8]
        bits = bits << 1
        bits += 1 if self[7, 8]

        5.downto(0) do |col_idx|
          bits = bits << 1
          bits += 1 if self[col_idx, 8]
        end

        format_string     = (bits ^ FORMAT_MASK).to_s(2).rjust(15, '0')

        # TODO check BCH error detection
        # TODO if too many errors, read alternate format blocks

        {
          :error_correction    => format_string[0,2].to_i(2),
          :mask_pattern        => format_string[2,3].to_i(2),
          :bch_error_detection => format_string[5..-1].to_i(2)
        }
      end
    end
  end
end

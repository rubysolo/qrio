module Qrio
  class QrMatrix < Matrix
    def initialize(*args)
      super
      @unmasked = false
    end

    FORMAT_MASK = 0b101_0100_0001_0010
    ERROR_CORRECTION_LEVEL = %w( M L H Q )
    MODE = {
      1 => :numeric,
      2 => :alphanumeric,
      4 => :ascii,
      8 => :kanji
    }
    WORD_WIDTHS = {
      :numeric      => { 1..9 => 10, 10..26 => 12, 27..40 => 14 },
      :alphanumeric => { 1..9 =>  9, 10..26 => 11, 27..40 => 13 },
      :ascii        => { 1..9 =>  8, 10..26 => 16, 27..40 => 16 },
      :kanji        => { 1..9 =>  8, 10..26 => 10, 27..40 => 12 }
    }

    def error_correction_level
      ERROR_CORRECTION_LEVEL[read_format[:error_correction]]
    end

    def mask_pattern
      read_format[:mask_pattern]
    end

    def version
      (width - 17) / 4
    end

    def unmask
      p = [
        lambda{|x,y| (x + y) % 2 == 0 },
        lambda{|x,y| x % 2 == 0 },
        lambda{|x,y| y % 3 == 0 },
        lambda{|x,y| (x + y) % 3 == 0 },
        lambda{|x,y| ((x / 2) + (y / 3)) % 2 == 0 },
        lambda{|x,y| ((x * y) % 2) + ((x * y) % 3) == 0 },
        lambda{|x,y| (((x * y) % 2) + ((x * y) % 3) % 2) == 0 },
        lambda{|x,y| (((x * y) % 3) + ((x + y) % 2) % 2) == 0 }
      ][mask_pattern]

      raise "could not load mask pattern #{ mask_pattern }" unless p

      0.upto(height - 1) do |y|
        0.upto(width - 1) do |x|
          if data_or_correction?(x, y)
            self[x, y] = self[x, y] ^ p.call(x, y)
          end
        end
      end

      @unmasked = ! @unmasked
    end

    def blocks
      @read_blocks ||= read_blocks
    end


    def to_s
      str = ""
      rows.each do |row|
        row.each do |m|
          str << (m ? '#' : ' ')
        end
        str << "\n"
      end

      str
    end

    def mode
      MODE[@mode]
    end

    def word_size
      @word_size ||= begin
        widths = WORD_WIDTHS[mode]
        version_width = widths.detect{|k,v| k.include? version }

        raise "Could not find word width" if version_width.nil?

        version_width.last
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

    def set_mode
      @pointer ||= 0
      @mode = read(4)
      raise "Unknown mode #{ @mode }" unless mode
    end

    def set_data_length
      @data_length = read(word_size)
    end

    # read +bits+ bits from the pattern and return the binary
    def read(bits)
      binary = []

      bits.times do |i|
        block_index, bit_index = @pointer.divmod(8)
        data = blocks[block_index]
        binary << (((data >> (7 - bit_index)) & 1) == 1)
        @pointer += 1
      end

      binary.map{|b| b ? '1' : '0' }.join.to_i(2)
    end

    def read_blocks
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

    def read_format
      @format ||= begin
        bits = 0

        0.upto(5) do |x|
          bits = bits << 1
          bits += 1 if self[x, 8]
        end

        bits = bits << 1
        bits += 1 if self[7, 8]
        bits = bits << 1
        bits += 1 if self[8, 8]
        bits = bits << 1
        bits += 1 if self[8, 7]

        5.downto(0) do |y|
          bits = bits << 1
          bits += 1 if self[8, y]
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

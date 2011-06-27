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
    ALIGNMENT_CENTERS = [
      [],
      [6, 18],
      [6, 22],
      [6, 26],
      [6, 30],
      [6, 34],
      [6, 22, 38],
      [6, 24, 42],
      [6, 26, 46],
      [6, 28, 50],

      [6, 30, 54],
      [6, 32, 58],
      [6, 34, 62],
      [6, 26, 46, 66],
      [6, 26, 48, 70],
      [6, 26, 50, 74],
      [6, 30, 54, 78],
      [6, 30, 56, 82],
      [6, 30, 58, 86],
      [6, 34, 62, 90],

      [6, 28, 50, 72, 94],
      [6, 26, 50, 74, 98],
      [6, 30, 54, 78, 102],
      [6, 28, 54, 80, 106],
      [6, 32, 58, 84, 110],
      [6, 30, 58, 86, 114],
      [6, 34, 62, 90, 118],
      [6, 26, 50, 74,  98, 122],
      [6, 30, 54, 78, 102, 126],
      [6, 26, 52, 78, 104, 130],

      [6, 26, 52, 78, 104, 130],
      [6, 30, 56, 82, 108, 134],
      [6, 34, 60, 86, 112, 138],
      [6, 30, 58, 86, 114, 142],
      [6, 34, 62, 90, 118, 146],
      [6, 30, 54, 78, 102, 126, 150],
      [6, 24, 50, 76, 102, 128, 154],
      [6, 28, 54, 80, 106, 132, 158],
      [6, 32, 58, 84, 110, 136, 162],
      [6, 26, 54, 82, 110, 138, 166],
      [6, 30, 58, 86, 114, 142, 170]
    ]

    BLOCK_STRUCTURE = [
      # to determine block structure, find the row corresponding to QR version
      # (row 0 = version 1), then find the column corresponding to ECC level
      # (M / L / H / Q)
      #
      # the result array will be:
      #   * block count
      #   * number of data bytes per block
      #   * nubmer of error correction bytes per block
      #   * (optional) number of blocks with one additional data byte
      #
      [[ 1, 16, 10    ], [ 1,  19,  7    ], [ 1,  9, 17    ], [ 1, 13, 13,   ]],
      [[ 1, 28, 16    ], [ 1,  34, 10    ], [ 1, 16, 28    ], [ 1, 22, 22,   ]],
      [[ 1, 44, 26    ], [ 1,  55, 15    ], [ 2, 13, 22    ], [ 2, 17, 18,   ]],
      [[ 2, 32, 18    ], [ 1,  80, 20    ], [ 4,  9, 16    ], [ 2, 24, 26,   ]],
      [[ 2, 43, 24    ], [ 1, 108, 26    ], [ 2, 11, 22,  2], [ 2, 15, 18,  2]],
      [[ 4, 27, 16    ], [ 2,  68, 18    ], [ 4, 15, 28,   ], [ 4, 19, 24,   ]],
      [[ 4, 31, 18    ], [ 2,  78, 20    ], [ 4, 13, 26,  1], [ 2, 14, 18,  4]],
      [[ 2, 38, 22,  2], [ 2,  97, 24    ], [ 4, 14, 26,  2], [ 4, 18, 22,  2]],
      [[ 3, 36, 22,  2], [ 2, 116, 30    ], [ 4, 12, 24,  4], [ 4, 16, 20,  4]],
      [[ 4, 43, 26,  1], [ 2,  68, 18,  2], [ 6, 15, 28,  2], [ 6, 19, 24,  2]],

      [[ 1, 50, 30,  4], [ 4,  81, 20    ], [ 3, 12, 24,  8], [ 4, 22, 28,  4]],
      [[ 6, 36, 22,  2], [ 2,  92, 24,  2], [ 7, 14, 28,  4], [ 4, 20, 26,  6]],
      [[ 8, 37, 22,  1], [ 4, 107, 26    ], [12, 11, 22,  4], [ 8, 20, 24,  4]],
      [[ 4, 40, 24,  5], [ 3, 115, 30,  1], [11, 12, 24,  5], [11, 16, 20,  5]],
      [[ 5, 41, 24,  5], [ 5,  87, 22,  1], [11, 12, 24,  7], [ 5, 24, 30,  7]],
      [[ 7, 45, 28,  3], [ 5,  98, 24,  1], [ 3, 15, 30, 13], [15, 19, 24,  2]],
      [[10, 46, 28,  1], [ 1, 107, 28,  5], [ 2, 14, 28, 17], [ 1, 22, 28, 15]],
      [[ 9, 43, 26,  4], [ 5, 120, 30,  1], [ 2, 14, 28, 19], [17, 22, 28,  1]],
      [[ 3, 44, 26, 11], [ 3, 113, 28,  4], [ 9, 13, 26, 16], [17, 21, 26,  4]],
      [[ 3, 41, 26, 13], [ 3, 107, 20,  5], [15, 15, 28, 10], [15, 24, 30,  5]],

      [[17, 42, 26    ], [ 4, 116, 28,  4], [19, 16, 30,  6], [17, 22, 28,  6]],
      [[17, 46, 28    ], [ 2, 111, 28,  7], [34, 13, 24,   ], [ 7, 24, 30, 16]],
      [[ 4, 47, 28, 14], [ 4, 121, 30,  5], [16, 15, 30, 14], [11, 24, 30, 14]],
      [[ 6, 45, 28, 14], [ 6, 117, 30,  4], [30, 16, 30,  2], [11, 24, 30, 16]],
      [[ 8, 47, 28, 13], [ 8, 106, 26,  4], [22, 15, 30, 13], [ 7, 24, 30, 22]],
      [[19, 46, 28,  4], [10, 114, 28,  2], [33, 16, 30,  4], [28, 22, 28,  6]],
      [[22, 45, 28,  3], [ 8, 122, 30,  4], [12, 15, 30, 28], [ 8, 23, 30, 26]],
      [[ 3, 45, 28, 23], [ 3, 117, 30, 10], [11, 15, 30, 31], [ 4, 24, 30, 31]],
      [[21, 45, 28,  7], [ 7, 116, 30,  7], [19, 15, 30, 26], [ 1, 23, 30, 37]],
      [[19, 47, 28, 10], [ 5, 115, 30, 10], [23, 15, 30, 25], [15, 24, 30, 25]],

      [[ 2, 46, 28, 29], [13, 115, 30,  3], [23, 15, 30, 28], [42, 24, 30,  1]],
      [[10, 46, 28, 23], [17, 115, 30    ], [19, 15, 30, 35], [10, 24, 30, 35]],
      [[14, 46, 28, 21], [17, 115, 30,  1], [11, 15, 30, 46], [29, 24, 30, 19]],
      [[14, 46, 28, 23], [13, 115, 30,  6], [59, 16, 30,  1], [44, 24, 30,  7]],
      [[12, 47, 28, 26], [12, 121, 30,  7], [22, 15, 30, 41], [39, 24, 30, 14]],
      [[ 6, 47, 28, 34], [ 6, 121, 30, 14], [ 2, 15, 30, 64], [46, 24, 30, 10]],
      [[29, 46, 28, 14], [17, 122, 30,  4], [24, 15, 30, 46], [49, 24, 30, 10]],
      [[13, 46, 28, 32], [ 4, 122, 30, 18], [42, 15, 30, 32], [48, 24, 30, 14]],
      [[40, 47, 28,  7], [20, 117, 30,  4], [10, 15, 30, 67], [43, 24, 30, 22]],
      [[18, 47, 28, 31], [19, 118, 30,  6], [20, 15, 30, 61], [34, 24, 30, 34]]
    ]

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
        lambda{|x,y| prod = x * y;   (prod % 2) + (prod % 3) == 0 },
        lambda{|x,y| prod = x * y; (((prod % 2) + (prod % 3)) % 2) == 0 },
        lambda{|x,y| prod = x * y; sum = x + y; (((prod % 3) + (sum % 2)) % 2) == 0 }
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

    # raw bytestream, as read from the QR symbol
    def raw_bytes
      @raw_bytes ||= read_raw_bytes
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

    def text
      @text ||= begin
        text = []

        unmask unless @unmasked

        # deinterlace
        @blocks = []

        byte_pointer = 0

        # TODO : handle ragged block sizes
        block_structure.each do |count, data, ecc|
          data.times do |word_index|
            block_count.times do |blk_index|
              @blocks[blk_index] ||= []
              @blocks[blk_index] << raw_bytes[byte_pointer]
              byte_pointer += 1
            end
          end
        end

        @blocks = @blocks.flatten

        set_mode

        character_count = read

        character_count.times do |idx|
          byte = read
          text << byte.chr
        end

        text.join
      end
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

    def block_count
      block_structure.inject(0){|sum, (blocks,data,ecc)| sum += blocks }
    end

    def block_structure
      @block_structure ||= begin
        @short_blocks = []
        @long_blocks  = []

        params = block_structure_params.dup

        @short_blocks = params.slice!(0,3)
        structure = [@short_blocks]

        unless params.empty?
          @long_blocks = @short_blocks.dup
          @long_blocks[0] = params[0]
          structure << @long_blocks
        end

        structure
      end
    end

    def ecc_bytes_per_block
      block_structure.first.last
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
      return false if version == 1

      alignment_centers = ALIGNMENT_CENTERS[version - 1]

      cy = alignment_centers.detect{|c| (c - y).abs <= 2 }
      cx = alignment_centers.detect{|c| (c - x).abs <= 2 }

      cx && cy && ! in_finder_pattern?(cx, cy)
    end

    def draw_alignment_patterns
      rows = ALIGNMENT_CENTERS[version - 1].dup
      cols = rows.dup

      cols.each do |cy|
        rows.each do |cx|
          unless in_finder_pattern?(cx, cy)
            ((cy - 2)...(cy + 2)).each do |y|
              ((cx - 2)...(cx + 2)).each do |x|
                self[x, y] = (cx - x).abs == 2 ||
                             (cy - y).abs == 2 ||
                             (x == cx && y == cy)
              end
            end
          end
        end
      end
    end

    def in_alignment_line?(x, y)
      (x == 6) || (y == 6)
    end

    private

    def set_mode
      @mode ||= begin
        @pointer ||= 0
        mode_number = read(4)
      end
      raise "Unknown mode #{ @mode }" unless mode
    end

    def set_data_length
      @data_length ||= read
    end

    def block_structure_params
      BLOCK_STRUCTURE[version - 1][read_format[:error_correction]].dup
    end

    # read +bits+ bits from bitstream and return the binary
    def read(bits=nil)
      bits ||= word_size
      binary = []

      bits.times do |i|
        block_index, bit_index = @pointer.divmod(8)
        data = @blocks[block_index] || 0
        binary << (((data >> (7 - bit_index)) & 1) == 1)
        @pointer += 1
      end

      binary.map{|b| b ? '1' : '0' }.join.to_i(2)
    end

    def read_raw_bytes
      @raw_bytes = []
      @byte      = []

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

      @raw_bytes
    end

    def add_bit(x, y)
      if data_or_correction?(x, y)
        @byte.push self[x, y]

        if @byte.length == 8
          @raw_bytes << @byte.map{|b| b ? '1' : '0' }.join.to_i(2)
          @byte = []
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

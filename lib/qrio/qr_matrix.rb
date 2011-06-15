require 'ruby-debug'

module Qrio
  class QrMatrix < Matrix
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
  end
end

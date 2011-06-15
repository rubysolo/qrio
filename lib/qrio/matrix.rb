module Qrio
  class Matrix
    attr_reader :width, :height

    def initialize(bits, width, height)
      @bits   = bits
      @width  = width
      @height = height
    end

    def to_s
      "<Matrix width:#{ width }, height: #{ height }>"
    end

    def [](x, y)
      rows[y][x] rescue nil
    end

    def []=(x, y, value)
      raise "Matrix index out of bounds" if x >= width || y >= height
      @bits[(width * y) + x] = value
      @rows = @columns = nil
    end

    def rows
      @rows ||= begin
        rows = []
        bits = @bits.dup

        while row = bits.slice!(0, @width)
          break if row.nil? || row.empty?
          rows << row
        end

        rows
      end
    end

    def columns
      @columns ||= begin
        columns = []
        width.times do |index|
          column = []

          rows.each do |row|
            column << row[index]
          end

          columns << column
        end

        columns
      end
    end

    def rotate
      new_bits = []
      columns.each do |column|
        new_bits += column.reverse
      end
      self.class.new(new_bits, @height, @width)
    end

    def extract(x, y, width, height)
      new_bits = []
      height.times do |offset|
        new_bits += rows[y + offset].slice(x, width)
      end
      self.class.new(new_bits, width, height)
    end
  end
end

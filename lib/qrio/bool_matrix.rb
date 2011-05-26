module Qrio
  class BoolMatrix
    attr_reader :width, :height

    def initialize(bits, width, height)
      @bits   = bits
      @width  = width
      @height = height
    end

    def [](x, y)
      rows[y][x]
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
  end
end

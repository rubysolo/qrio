module Qrio
  module ImageLoader
    class PNGImageLoader
      def self.load(filename)
        image = ChunkyPNG::Image.from_file(filename)

        bits = image.pixels.map do |pixel|
          grayscale = ChunkyPNG::Color.to_grayscale(pixel)
          level = ChunkyPNG::Color.r(grayscale)
          level <= 126
        end

        BoolMatrix.new(bits, image.width, image.height)
      end
    end
  end
end


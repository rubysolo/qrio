module Qrio
  # this module contains the code to dump images of QR decoding
  # progress.  useful for debugging or those curious about the
  # detection / decoding algorithms
  module ImageDumper
    def save_image(filename, options={})
      png = ChunkyPNG::Image.new(
        @input_matrix.width,
        @input_matrix.height,
        ChunkyPNG::Color::WHITE
      )

      (0..(@input_matrix.width - 1)).to_a.each do |x|
        (0..(@input_matrix.height - 1)).to_a.each do |y|
          png[x, y] = ChunkyPNG::Color::BLACK if @input_matrix[x, y]
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
        @sampling_grid.angles[0, 100].each do |angle|
          png.line_xiaolin_wu(*angle.to_coordinates, color(:cyan))
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
  end
end

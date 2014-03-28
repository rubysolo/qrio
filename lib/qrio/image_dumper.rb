module Qrio
  # this module contains the code to dump images of QR decoding
  # progress.  useful for debugging or those curious about the
  # detection / decoding algorithms
  module ImageDumper
    def save_image(filename, options={})
      if matrix = @extracted_matrix
        # extracted matrix is already cropped
        options[:crop] = false
        @features = {
          :candidates      => {},
          :matches         => @translated_matches,
          :finder_patterns => @sampling_grid.finder_patterns
        }
      else
        matrix = @input_matrix
        @features = {
          :candidates      => @candidates,
          :matches         => @matches,
          :finder_patterns => @finder_patterns
        }
      end

      save_to_image(matrix, filename, options)
    end

    def save_to_image(matrix, filename, options={})
      png = ChunkyPNG::Image.new(
        matrix.width,
        matrix.height,
        ChunkyPNG::Color::WHITE
      )

      (0..(matrix.width - 1)).to_a.each do |x|
        (0..(matrix.height - 1)).to_a.each do |y|
          png[x, y] = ChunkyPNG::Color::BLACK if matrix[x, y]
        end
      end

      png = extract_options(png, options)

      png = png.crop(*@qr_bounds.to_point_size) if options[:crop]
      png.save(filename, :fast_rgba)
    end

    def extract_options(png, options)
      if options[:annotate]
        if options[:annotate].include?(:candidates)
          @features[:candidates][:horizontal].each do |hmatch|
            png = png.rect(*hmatch.to_coordinates, color(:green))
          end

          @features[:candidates][:vertical].each do |vmatch|
            png = png.rect(*vmatch.to_coordinates, color(:magenta))
          end
        end

        if options[:annotate].include?(:matches)
          @features[:matches][:horizontal].each do |hmatch|
           png = png.rect(*hmatch.to_coordinates, color(:green))
          end

          @features[:matches][:vertical].each do |vmatch|
           png = png.rect(*vmatch.to_coordinates, color(:magenta))
          end
        end

        if options[:annotate].include?(:finder_patterns)
          @features[:finder_patterns].each do |finder_pattern|
            png =  png.rect(*finder_pattern.to_coordinates, color(:red))
          end
        end

        if options[:annotate].include?(:angles)
          @sampling_grid.angles[0, 100].each do |angle|
           png =  png.line_xiaolin_wu(*angle.to_coordinates, color(:cyan))
          end
        end

        if options[:annotate].include?(:alignment_patterns)
          png = png.rect(*@alignment_pattern.to_coordinates, color(:magenta))
        end

        if options[:annotate].include?(:extracted_pixels)
          @sampling_grid.extracted_pixels do |x, y|
            png = png.circle(x, y, 1, color(:cyan))
          end
        end
      end
      png
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

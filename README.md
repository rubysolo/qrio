# QRio

QRio is a QR code decoder for Ruby

## Usage

QRio can extract QR contents in one step:

    require 'qrio'
    puts Qrio::Qr.load("some-image.png").text

If you know / are curious about the decoding process, QRio can generate
an image illustrating the intermediate steps to decoding:

    require 'qrio'
    qr = Qrio::Qr.load("some-image.png")

    qr.save_image(
      "some-image-annotated.png",
      :crop => true,      # crop output image to detected QR bounds
      :annotate => [
        :finder_patterns, # outline detected finder patterns
        :angles           # draw lines connecting finder pattern centers
      ]
    )

    


## Dependencies

ChunkyPNG (tested with version 1.2.0)

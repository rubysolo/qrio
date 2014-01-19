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

* Ruby 1.9.2 (will be backported to 1.8.7)
* ChunkyPNG (tested with version 1.2.0)

## STATUS

*NOTE* : QRio is not yet fully functional.  If you'd like to help out, fork and
submit a tested pull request.  :)

### TODO

* support numeric / alphanumeric / kanji QR codes
* refine alignment pattern location and adjust module sampling grid
  accordingly
* error correction support
* support more image formats (limited to PNG at the moment)
* native thresholding for input images
* support more QR versions
* speed improvements

### Does *anything* work?

Yeah, it's coming along.  Here's what should be working now:

* find and extract a QR code from an image.  I've been cheating
  somewhat, using image magick to threshold the image for me:

      convert raw.jpg -colorspace Gray -lat 90x90-3% -median 1x1 cooked.png

* detect and correct orientation of extracted QR
* extract modules via a sampling grid
* extract raw bytes from data / error correction blocks
* de-interlace blocks into final bitstream
* extract text from bitstream (ascii mode only)



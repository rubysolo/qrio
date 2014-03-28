require 'tempfile'
require_relative '../lib/qrio'
require 'test/unit'

class TestImageDumper < Test::Unit::TestCase

  def setup
    @qr = Qrio::Qr.load(File.expand_path("../fixtures/sample.png", __FILE__))
  end

  def test_save_image_without_options
    file = Tempfile.new(['tmp', 'png'])
    assert_not_nil  @qr.save_image(
                          file.path,
                          :crop => true
                        )
    file.rewind
    file.close
    file.unlink
  end

  def test_save_image_with_options
    file = Tempfile.new(['tmp', 'png'])
    assert_not_nil  @qr.save_image(
                          file.path,
                          :crop => true,
                          :annotate => [
                             :finder_patterns,
                             :angles
                          ]
                        )
    file.rewind
    file.close
    file.unlink
  end

end

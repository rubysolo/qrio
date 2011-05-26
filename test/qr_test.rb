require_relative '../lib/qrio'
require 'test/unit'

class TestQr < Test::Unit::TestCase
  def setup
    @qr = Qrio::Qr.new
  end

  def test_grouping
    [
      [26,4,81],
      [27,4,81],
      [28,4,81],
      [29,4,81],
      [30,3,81],
      [31,4,81],
      [32,4,81],
      [33,4,81],
      [34,3,80],
      [35,3,81],
      [36,3,81],
      [37,3,81],
      [38,4,81],
      [39,4,82],
      [40,4,80],
      [42,3,81],
      [43,3,80],
      [44,4,81],
      [45,4,81],
      [46,3,81],
      [47,3,81],
      [48,4,81],
      [49,4,80],
      [50,3,81],
      [51,4,81],
      [54,4,81],
      [55,4,81],
      [56,4,81],
      [57,3,81],
      [58,4,81]
    ].each do |(offset, origin, terminus)|
      slice = Qrio::HorizontalMatch.build(offset, origin, terminus)
      @qr.add_candidate(slice, :horizontal)
    end

    assert_equal 1, @qr.candidates[:horizontal].length
  end

  def test_rle
    assert_equal [4, 2, 3], @qr.rle([1, 1, 1, 1, 0, 0, 1, 1, 1])
    assert_equal [4, 2, 3], @qr.rle([true, true, true, true, false, false, true, true, true])
  end

  def test_slice_detection
    @qr.load_image(fixture_img_path("finder_pattern1.png"))
    @qr.scan(:horizontal)
    @qr.scan(:vertical)
    @qr.filter_candidates

    assert_equal 1, @qr.matches[:horizontal].length
    hmatch = @qr.matches[:horizontal].first
    assert_dimensions(hmatch, 10, 27, 52, 19)

    assert_equal 1, @qr.matches[:vertical].length
    vmatch = @qr.matches[:vertical].first
    assert_dimensions(vmatch, 26, 10, 18, 52)

    @qr.load_image(fixture_img_path("finder_pattern3.png"))
    @qr.scan(:horizontal)
    @qr.scan(:vertical)
    @qr.filter_candidates

    assert_equal 1, @qr.matches[:horizontal].length
    hmatch = @qr.matches[:horizontal].first
    assert_dimensions(hmatch, 5, 21, 53, 16)

    assert_equal 1, @qr.matches[:vertical].length
    vmatch = @qr.matches[:vertical].first
    assert_dimensions(vmatch, 22, 3, 17, 52)

    @qr.load_image(fixture_img_path("finder_pattern4.png"))
    @qr.scan(:horizontal)
    @qr.scan(:vertical)
    @qr.filter_candidates

    assert_equal 0, @qr.matches[:horizontal].length
    assert_equal 0, @qr.matches[:vertical].length
  end

  private

  def assert_dimensions(region, left, top, width, height)
    assert_equal left,   region.left
    assert_equal top,    region.top
    assert_equal width,  region.width
    assert_equal height, region.height
  end

  def fixture_img_path(filename)
    File.expand_path("../fixtures/#{ filename }", __FILE__)
  end
end

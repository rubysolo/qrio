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

  def test_finder_pattern_detection
    assert_contains_finder_pattern(
      "finder_pattern1.png",
      [10, 27, 52, 19],
      [26, 10, 18, 52]
    )

    assert_contains_finder_pattern(
      "finder_pattern3.png",
      [5, 21, 52, 16],
      [21, 3, 17, 51]
    )

    assert_contains_finder_pattern(
      "finder_pattern4.png",
      [3, 26, 79, 34],
      [26, 3, 31, 80]
    )
  end

  private

  def assert_contains_finder_pattern(img, h, v)
    @qr.load_image fixture_img_path(img)
    @qr.scan(:horizontal)
    @qr.scan(:vertical)
    @qr.filter_candidates

    assert_equal 1, @qr.matches[:horizontal].length
    hmatch = @qr.matches[:horizontal].first
    assert_dimensions(hmatch, *h)

    assert_equal 1, @qr.matches[:vertical].length
    vmatch = @qr.matches[:vertical].first
    assert_dimensions(vmatch, *v)

    @qr.find_intersections
    assert_equal 1, @qr.finder_patterns.length
  end

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

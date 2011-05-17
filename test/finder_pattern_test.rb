require File.expand_path('../../lib/qrio', __FILE__)
require 'test/unit'

class TestQrioFinderPattern < Test::Unit::TestCase
  def setup
    @fp = Qrio::FinderPattern
  end

  def test_ratio_matching
    assert @fp.matches_finder_pattern?([ 1, 1, 3, 1, 1])
    assert @fp.matches_finder_pattern?([10,10,30,10,10])
    assert @fp.matches_finder_pattern?([11, 9,28,10,12])
    assert @fp.matches_finder_pattern?([ 8, 8,19, 9, 8])
  end

  def test_slice_detection
    img = Magick::Image.read(fixture_img_path("finder_pattern1.png")).first
    hslices = @fp.find_matches(img, :horizontal)

    assert_equal 1, hslices.length
    hslice = hslices.first

    assert_equal 16, hslice.left_edge
    assert_equal 27, hslice.top_edge
    assert_equal 62, hslice.right_edge
    assert_equal 45, hslice.bottom_edge

    vslices = @fp.find_matches(img, :vertical)

    assert_equal 1, vslices.length
    vslice = vslices.first

    assert_equal 27, vslice.left_edge
    assert_equal 16, vslice.top_edge
    assert_equal 44, vslice.right_edge
    assert_equal 62, vslice.bottom_edge
  end

  def test_finder_pattern_detection
    img = Magick::Image.read(fixture_img_path("finder_pattern1.png")).first
    finder_patterns = @fp.extract(img)
    assert_equal 1, finder_patterns.length

    fp = finder_patterns.first
    assert_equal 10, fp.top_edge
    assert_equal 10, fp.left_edge
    assert_equal 52, fp.width
    assert_equal 52, fp.height
  end

  private

  def fixture_img_path(filename)
    File.expand_path("../fixtures/#{ filename }", __FILE__)
  end
end

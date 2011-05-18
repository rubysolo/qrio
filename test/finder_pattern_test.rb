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
    assert @fp.matches_finder_pattern?([11,12,34,13,12])
    assert @fp.matches_finder_pattern?([12,20,46,19,14])
  end

  def test_slice_detection
    img = Magick::Image.read(fixture_img_path("finder_pattern1.png")).first
    hslices = @fp.find_matches(img, :horizontal)

    assert_equal 1, hslices.length
    hslice = hslices.first

    assert_equal 10, hslice.left_edge
    assert_equal 27, hslice.top_edge
    assert_equal 62, hslice.right_edge
    assert_equal 45, hslice.bottom_edge

    vslices = @fp.find_matches(img, :vertical)

    assert_equal 1, vslices.length
    vslice = vslices.first

    assert_equal 27, vslice.left_edge
    assert_equal 10, vslice.top_edge
    assert_equal 44, vslice.right_edge
    assert_equal 62, vslice.bottom_edge

    img = Magick::Image.read(fixture_img_path("finder_pattern3.png")).first
    hslices = @fp.find_matches(img, :horizontal)

    assert_equal 1, hslices.length
    hslice = hslices.first

    assert_equal  5, hslice.left_edge
    assert_equal 21, hslice.top_edge
    assert_equal 57, hslice.right_edge
    assert_equal 36, hslice.bottom_edge

    vslices = @fp.find_matches(img, :vertical)

    assert_equal 1, vslices.length
    vslice = vslices.first

    assert_equal 22, vslice.left_edge
    assert_equal  3, vslice.top_edge
    assert_equal 38, vslice.right_edge
    assert_equal 54, vslice.bottom_edge
  end

  def test_finder_pattern_detection
    assert_finder_pattern("finder_pattern1.png", [[10, 10, 53, 53]])
    assert_finder_pattern("finder_pattern2.png", [[ 5,  4, 52, 51]])
    assert_finder_pattern("finder_pattern3.png", [[ 3,  5, 53, 52]])

    assert_no_finder_pattern("no_finder_pattern1.png")
  end

  private

  # coordinates should be an array of arrays
  def assert_finder_pattern(filename, coordinates)
    img = Magick::Image.read(fixture_img_path(filename)).first
    finder_patterns = @fp.extract(img)
    assert_equal coordinates.length, finder_patterns.length
    finder_patterns.zip(coordinates).each do |fp, c|
      assert_equal c[0], fp.top_edge
      assert_equal c[1], fp.left_edge
      assert_equal c[2], fp.width
      assert_equal c[3], fp.height
    end
  end

  def assert_no_finder_pattern(filename)
    img = Magick::Image.read(fixture_img_path(filename)).first
    finder_patterns = @fp.extract(img)
    assert_equal 0, finder_patterns.length
  end

  def fixture_img_path(filename)
    File.expand_path("../fixtures/#{ filename }", __FILE__)
  end
end

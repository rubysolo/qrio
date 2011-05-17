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

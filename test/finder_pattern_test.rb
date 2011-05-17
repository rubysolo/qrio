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

  def test_orientation_detection
    slice1 = @fp::Slice.new(0, 2, 8, 2)
    assert slice1.horizontal?
    assert ! slice1.vertical?

    slice2 = @fp::Slice.new(2, 0, 2, 8)
    assert ! slice2.horizontal?
    assert slice2.vertical?

    slice3 = @fp::Slice.new(0, 0, 8, 8)
    assert ! slice3.horizontal?
    assert ! slice3.vertical?
  end

  def test_slice_adjacency
    slice1 = @fp::Slice.new(0, 2, 8, 2)
    assert slice1.adjacent?(@fp::Slice.new(0, 3, 8, 3))
    assert ! slice1.adjacent?(@fp::Slice.new(5, 3, 13, 3))
  end

  def test_union
    slice1 = @fp::Slice.new(0, 2, 8, 2)
    slice2 = @fp::Slice.new(0, 3, 8, 3)

    assert slice1.adjacent?(slice2)
    assert slice2.adjacent?(slice1)

    slice2 = slice1.union slice2

    assert_equal 2, slice2.height
    assert_equal 0, slice2.left_edge
    assert_equal 8, slice2.right_edge
    assert_equal 2, slice2.top_edge
    assert_equal 3, slice2.bottom_edge

    slice3 = @fp::Slice.new(0, 4, 8, 4)
    assert slice2.adjacent?(slice3)
    assert slice3.adjacent?(slice2)

    slice3 = slice2.union slice3

    assert_equal 3, slice3.height
    assert_equal 0, slice3.left_edge
    assert_equal 8, slice3.right_edge
    assert_equal 2, slice3.top_edge
    assert_equal 4, slice3.bottom_edge

    slice4 = @fp::Slice.new(0, 6, 8, 6)
    assert slice3.adjacent?(slice4)
    assert slice4.adjacent?(slice3)

    slice4 = slice3.union slice4

    assert_equal 5, slice4.height
    assert_equal 0, slice4.left_edge
    assert_equal 8, slice4.right_edge
    assert_equal 2, slice4.top_edge
    assert_equal 6, slice4.bottom_edge
  end
end

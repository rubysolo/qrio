require_relative '../lib/qrio'
require 'test/unit'

class TestRegion < Test::Unit::TestCase
  def test_region_basics
    region = Qrio::Region.new(1, 1, 4, 4)

    assert_equal [1, 1], region.top_left
    assert_equal [4, 4], region.bottom_right

    assert_equal 4, region.width
    assert_equal 4, region.height
  end

  def test_orientation_detection
    region = Qrio::Region.new(0, 2, 8, 2)
    assert region.horizontal?
    assert ! region.vertical?

    region = Qrio::Region.new(2, 0, 2, 8)
    assert ! region.horizontal?
    assert region.vertical?

    region = Qrio::Region.new(0, 0, 8, 8)
    assert ! region.horizontal?
    assert ! region.vertical?
  end

  def test_union
    slice1 = Qrio::Region.new(0, 2, 8, 2)
    slice2 = Qrio::Region.new(0, 3, 8, 3)

    slice2 = slice1.union slice2

    assert_equal 2, slice2.height
    assert_equal 0, slice2.left
    assert_equal 8, slice2.right
    assert_equal 2, slice2.top
    assert_equal 3, slice2.bottom

    slice3 = slice2.union Qrio::Region.new(0, 4, 8, 4)

    assert_equal 3, slice3.height
    assert_equal 0, slice3.left
    assert_equal 8, slice3.right
    assert_equal 2, slice3.top
    assert_equal 4, slice3.bottom

    slice4 = slice3.union Qrio::Region.new(0, 6, 8, 6)

    assert_equal 5, slice4.height
    assert_equal 0, slice4.left
    assert_equal 8, slice4.right
    assert_equal 2, slice4.top
    assert_equal 6, slice4.bottom
  end
  
  def test_equality_detection
    slice1 = Qrio::Region.new(0, 2, 8, 2)
    slice2 = Qrio::Region.new(0, 2, 8, 2)

    assert_equal slice1, slice2
    assert slice1.eql?(slice2)
  end

  def test_translation
    region = Qrio::Region.new(7, 7, 10, 10)
    translated = region.translate(7, 7)
    assert_equal "R[0,0,3,3]", translated.to_s
  end
end

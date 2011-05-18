require File.expand_path('../../lib/qrio', __FILE__)
require 'test/unit'

class TestQrioNeighbor < Test::Unit::TestCase
  def setup
    @s = Qrio::Slice
    @n = Qrio::Neighbor
  end

  def test_calculations
    s1 = @s.new(169, 140, 284, 256)
    s2 = @s.new(173, 435, 286, 546)
    s3 = @s.new(463, 140, 578, 256)

    n12 = @n.new(s1, s2)
    assert_equal '-1.561', '%.3f' % n12.angle
    assert_equal 293, n12.distance.round
    assert n12.right_angle?

    n21 = @n.new(s2, s1)
    assert_equal '1.581', '%.3f' % n21.angle
    assert_equal 293, n21.distance.round
    assert n21.right_angle?

    n23 = @n.new(s2, s3)
    assert_equal '0.788', '%.3f' % n23.angle
    assert_equal 413, n23.distance.round
    assert ! n23.right_angle?

    n32 = @n.new(s3, s2)
    assert_equal '-2.354', '%.3f' % n32.angle
    assert_equal 413, n32.distance.round
    assert ! n32.right_angle?

    n31 = @n.new(s3, s1)
    assert_equal '3.142', '%.3f' % n31.angle
    assert_equal 294, n31.distance.round
    assert n31.right_angle?

    n13 = @n.new(s1, s3)
    assert_equal '0.000', '%.3f' % n13.angle
    assert_equal 294, n13.distance.round
    assert n13.right_angle?
  end
end

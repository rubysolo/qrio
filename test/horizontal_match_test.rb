require_relative '../lib/qrio'
require 'test/unit'

class TestHorizontalMatch < Test::Unit::TestCase
  def test_adjacency_detection
    hmatch1 = Qrio::HorizontalMatch.build(2, 0, 8)
    hmatch2 = Qrio::HorizontalMatch.build(3, 0, 8)
    hmatch3 = Qrio::HorizontalMatch.build(3, 5, 13)

    assert hmatch1.origin_matches?(hmatch2)
    assert hmatch1.terminus_matches?(hmatch2)
    assert hmatch1.endpoints_match?(hmatch2)
    assert hmatch1.offset_matches?(hmatch2)
    assert hmatch1.adjacent?(hmatch2)

    refute hmatch1.adjacent?(hmatch3)

    # slice1 = @s.new(3, 26, 82, 39)
    # slice2 = @s.new(3, 40, 81, 58)
    # assert slice1.adjacent?(slice2)
  end

  def test_slice_sorting
    input = [
      [2, 0, 8],
      [3, 1, 9],
      [4, 0, 8]
    ].map{|c| Qrio::HorizontalMatch.build(*c) }
    output = input.sort

    assert_equal [0, 1, 0], output.map{|s| s.left }
    assert_equal [2, 3, 4], output.map{|s| s.top }
  end
end

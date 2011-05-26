require_relative '../lib/qrio'
require 'test/unit'

class TestFinderPatternSlice < Test::Unit::TestCase
  def test_ratio_matching
    [
      [ 1, 1, 3, 1, 1],
      [10,10,30,10,10],
      [11, 9,28,10,12],
      [ 8, 8,19, 9, 8],
      [11,12,34,13,12],
      [12,20,46,19,14],
      [10,13,32,14, 8],
      [10,12,34,13, 7],
      [11,13,32,14, 8],
    ].each{|b| assert_matches_ratio b }

    (9..12).to_a.each do |a|
      (11..13).to_a.each do |b|
        (31..34).to_a.each do |c|
          (13..15).to_a.each do |d|
            (7..9).to_a.each do |e|
              assert_matches_ratio [a, b, c, d, e]
            end
          end
        end
      end
    end
  end

  def test_intersection_detection
   slice1 = Qrio::HorizontalMatch.build(27, 16, 62)
   slice1 = slice1.union Qrio::HorizontalMatch.build(45, 16, 62)

   slice2 = Qrio::VerticalMatch.build(27, 16, 62)
   slice2 = slice2.union Qrio::VerticalMatch.build(44, 16, 62)

   assert slice1.length_matches?(slice2), "length diff: #{ slice1.length_diff(slice2) }"
   assert slice1.breadth_matches?(slice2), "breadth diff: #{ slice1.breadth_diff(slice2) }"
   assert slice1.intersects? slice2

   slice1 = Qrio::HorizontalMatch.build(21, 5, 57)
   slice1 = slice1.union Qrio::HorizontalMatch.build(35, 5, 57)

   slice2 = Qrio::VerticalMatch.build(22, 3, 54)
   slice2 = slice2.union Qrio::VerticalMatch.build(38, 3, 54)

   assert slice1.intersects? slice2
  end

=begin
  def test_slice_ratio
    correct = [
      [16, 27, 62, 45],
      [27, 16, 44, 62],
      [10, 27, 62, 45],
      [27, 10, 44, 62],
      [ 5, 21, 57, 35]
    ].map{|a| @s.new(*a) }

    correct.each do |slice|
      assert slice.has_correct_ratio?, slice.ratio
    end

    incorrect = [
      [16, 27, 62, 28],
      [27, 16, 30, 62],
    ].map{|a| @s.new(*a) }

    incorrect.each do |slice|
      assert ! slice.has_correct_ratio?, slice.ratio
    end
  end
=end

  def test_slice_builder
    slice = Qrio::FinderPatternSlice.build_matching(10, 5, [1, 1, 3, 1, 1], :horizontal)
    assert slice.is_a?(Qrio::HorizontalMatch)
    assert_equal 10, slice.offset
    assert_equal 5, slice.origin
    assert_equal 11, slice.terminus
    assert_equal 5, slice.left
    assert_equal 11, slice.right
    assert_equal 10, slice.top
    assert_equal 10, slice.bottom
    assert_equal 1, slice.height
    assert_equal 7, slice.width

    slice = Qrio::FinderPatternSlice.build_matching(23, 15, [1, 1, 3, 1, 1], :vertical)
    assert slice.is_a?(Qrio::VerticalMatch)
    assert_equal 23, slice.offset
    assert_equal 15, slice.origin
    assert_equal 21, slice.terminus
    assert_equal 23, slice.left
    assert_equal 23, slice.right
    assert_equal 15, slice.top
    assert_equal 21, slice.bottom
    assert_equal 7, slice.height
    assert_equal 1, slice.width
  end

  private

  def assert_matches_ratio(widths)
    norm = Qrio::FinderPatternSlice.normalized_ratio(widths)
    norm = norm.map{|n| '%.2f' % n }
    msg  = "Expected #{ widths.join('|') } [#{ norm.join('|') }]"
    msg << " to match finder pattern ratio"
    assert Qrio::FinderPatternSlice.matches_ratio?(widths), msg
  end
end

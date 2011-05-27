require_relative '../lib/qrio'
require 'test/unit'

class TestSamplingGrid < Test::Unit::TestCase
  def setup
    @matrix = Qrio::BoolMatrix.new(Array.new(441, false), 21, 21)
  end

  def test_orientation_detection
    finder_patterns = build_finder_patterns([
      [ 0, 0, 6, 6],
      [14, 0,20, 6],
      [ 0,14, 6,20]
    ])

    grid = Qrio::SamplingGrid.new(@matrix, finder_patterns)
    assert_equal "F[0,0,6,6]", grid.origin_corner.to_s
    assert_equal 0, grid.orientation
    assert_equal 1, grid.provisional_version

    finder_patterns = build_finder_patterns([
      [ 0, 0, 6, 6],
      [14, 0,20, 6],
      [14,14,20,20]
    ])

    grid = Qrio::SamplingGrid.new(@matrix, finder_patterns)
    assert_equal "F[14,0,20,6]", grid.origin_corner.to_s
    assert_equal 1, grid.orientation
    assert_equal 1, grid.provisional_version

    finder_patterns = build_finder_patterns([
      [14, 0,20, 6],
      [14,14,20,20],
      [ 0,14, 6,20]
    ])

    grid = Qrio::SamplingGrid.new(@matrix, finder_patterns)
    assert_equal "F[14,14,20,20]", grid.origin_corner.to_s
    assert_equal 2, grid.orientation
    assert_equal 1, grid.provisional_version

    finder_patterns = build_finder_patterns([
      [14,14,20,20],
      [ 0,14, 6,20],
      [ 0, 0, 6, 6],
    ])

    grid = Qrio::SamplingGrid.new(@matrix, finder_patterns)
    assert_equal "F[0,14,6,20]", grid.origin_corner.to_s
    assert_equal 3, grid.orientation
    assert_equal 1, grid.provisional_version
  end

  def test_slight_rotation
    finder_patterns = build_finder_patterns([
      [105,217,155,266],
      [290,216,341,266],
      [100,401,151,452]
    ])

    grid = Qrio::SamplingGrid.new(@matrix, finder_patterns)
    assert_equal "F[105,217,155,266]", grid.origin_corner.to_s
    assert_equal 0, grid.orientation
    assert_equal 3, grid.provisional_version
    assert_equal '7.38', ('%.2f' % grid.block_width)
    assert_equal '7.29', ('%.2f' % grid.block_height)
  end


  private

  def build_finder_patterns(arrays)
    arrays.map do |coordinates|
      Qrio::FinderPatternSlice.new(*coordinates)
    end
  end
end

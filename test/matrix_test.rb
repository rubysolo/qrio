require_relative '../lib/qrio'
require 'test/unit'

class TestMatrix < Test::Unit::TestCase
  def test_random_access
    matrix = Qrio::Matrix.new([1, 1, 0, 0], 2, 2)
    assert_equal 2, matrix.rows.length
    assert_equal 2, matrix.columns.length

    assert_equal [1, 1], matrix.rows[0]
    assert_equal [0, 0], matrix.rows[1]
    assert_equal [1, 0], matrix.columns[0]
    assert_equal [1, 0], matrix.columns[1]

    assert_equal 1, matrix[0, 0]
    assert_equal 0, matrix[0, 1]
    assert_equal 1, matrix[1, 0]
    assert_equal 0, matrix[1, 1]
  end

  def test_rotation
    matrix = Qrio::Matrix.new([1, 0, 1, 0, 0, 0, 0, 1, 0], 3, 3)
    rotated = matrix.rotate

    assert_equal [0, 0, 1], rotated.rows[0]
    assert_equal [1, 0, 0], rotated.rows[1]
    assert_equal [0, 0, 1], rotated.rows[2]
  end
end

require File.expand_path('../../lib/qrio', __FILE__)
require 'test/unit'

class TestQrioFinderPattern < Test::Unit::TestCase
  def setup
    @fp = Qrio::FinderPattern
    @s  = Qrio::Slice
  end

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

  def test_grouping
    input = [
      [4,26,81,26],
      [4,27,81,27],
      [4,28,81,28],
      [4,29,81,29],
      [3,30,81,30],
      [4,31,81,31],
      [4,32,81,32],
      [4,33,81,33],
      [3,34,80,34],
      [3,35,81,35],
      [3,36,81,36],
      [3,37,81,37],
      [4,38,81,38],
      [4,39,82,39],
      [4,40,80,40],
      [3,42,81,42],
      [3,43,80,43],
      [4,44,81,44],
      [4,45,81,45],
      [3,46,81,46],
      [3,47,81,47],
      [4,48,81,48],
      [4,49,80,49],
      [3,50,81,50],
      [4,51,81,51],
      [4,52,81,52],
      [4,53,81,53],
      [4,54,81,54],
      [4,55,81,55],
      [4,56,81,56],
      [3,57,81,57],
      [4,58,81,58]
    ].map{|c| @s.new(*c) }
    sorted = input.sort
    assert_equal input, sorted
    output = @fp.group_adjacent input

    assert_equal 1, output.length
  end

  def test_slice_detection
    img = Magick::Image.read(fixture_img_path("finder_pattern1.png")).first
    hslices = @fp.find_matches(img, :horizontal)
    assert_equal 1, hslices.length
    hslice = hslices.first
    assert_dimensions(hslice, 10, 27, 53, 19)

    vslices = @fp.find_matches(img, :vertical)
    assert_equal 1, vslices.length
    vslice = vslices.first
    assert_dimensions(vslice, 27, 10, 18, 53)

    img = Magick::Image.read(fixture_img_path("finder_pattern3.png")).first
    hslices = @fp.find_matches(img, :horizontal)
    assert_equal 1, hslices.length
    hslice = hslices.first
    assert_dimensions(hslice, 5, 21, 53, 16)

    vslices = @fp.find_matches(img, :vertical)
    assert_equal 1, vslices.length
    vslice = vslices.first
    assert_dimensions(vslice, 22, 3, 17, 52)

    img = Magick::Image.read(fixture_img_path("finder_pattern4.png")).first
    hslices = @fp.find_matches(img, :horizontal)
    assert_equal 1, hslices.length, hslices.map(&:to_s)
    hslice = hslices.first
    assert_dimensions(hslice, 3, 26, 80, 33)
  end

  def test_finder_pattern_detection
    assert_finder_pattern("finder_pattern1.png", [[10, 10, 53, 53]])
    assert_finder_pattern("finder_pattern2.png", [[ 4,  5, 52, 51]])
    assert_finder_pattern("finder_pattern3.png", [[ 5,  3, 53, 52]])
    assert_finder_pattern("finder_pattern4.png", [[ 3,  3, 80, 81]])

    assert_no_finder_pattern("no_finder_pattern1.png")
  end

  private

  # coordinates should be an array of arrays
  def assert_finder_pattern(filename, coordinates)
    img = Magick::Image.read(fixture_img_path(filename)).first
    finder_patterns = @fp.extract(img)
    assert_equal coordinates.length, finder_patterns.length
    finder_patterns.zip(coordinates).each do |fp, c|
      assert_dimensions(fp, *c)
    end
  end

  def assert_no_finder_pattern(filename)
    img = Magick::Image.read(fixture_img_path(filename)).first
    finder_patterns = @fp.extract(img)
    assert_equal 0, finder_patterns.length
  end

  def assert_dimensions(pattern, left, top, width, height)
    assert_equal left,   pattern.left_edge
    assert_equal top,    pattern.top_edge
    assert_equal width,  pattern.width
    assert_equal height, pattern.height
  end

  def assert_matches_ratio(widths)
    assert @fp.matches_finder_pattern?(widths), "expected #{ widths.join('|')} (#{ @fp.normalized_ratio(widths).map{|w| '%.2f' % w }.join('|') }) to match FP ratio"
  end

  def fixture_img_path(filename)
    File.expand_path("../fixtures/#{ filename }", __FILE__)
  end
end

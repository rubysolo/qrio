require_relative '../lib/qrio'
require 'test/unit'

class TestQrMatrix < Test::Unit::TestCase
  def setup
    @bits, @qr = make_qr("block_test")
  end

  def test_to_s
    assert_equal bits_to_string(@bits, @qr.width), @qr.to_s
  end

  def test_format_detection
    @qr[1, 8] = false
    assert_equal 'M', @qr.error_correction_level
  end


  def test_dimensions
    assert_equal 25, @qr.width
    assert_equal 25, @qr.height
  end

  def test_position_detection
    assert @qr.in_finder_pattern?(0, 6)
    assert @qr.in_finder_pattern?(0, 7)
    assert @qr.in_finder_pattern?(0, 8)
    refute @qr.in_finder_pattern?(0, 9)

    assert @qr.in_finder_pattern?(6, 0)
    assert @qr.in_finder_pattern?(7, 0)
    assert @qr.in_finder_pattern?(8, 0)
    refute @qr.in_finder_pattern?(9, 0)

    assert @qr.in_finder_pattern?(8, 3)

    assert @qr.in_alignment_line?(14, 6)
    assert @qr.in_alignment_line?(6, 14)


    assert_equal 2, @qr.version
    assert @qr.in_alignment_pattern?(16, 16)
    assert @qr.in_alignment_pattern?(18, 18)
    assert @qr.in_alignment_pattern?(20, 20)

    refute @qr.in_alignment_pattern?(15, 16)
    refute @qr.in_alignment_pattern?(16, 15)

    refute @qr.in_alignment_pattern?(21, 20)
    refute @qr.in_alignment_pattern?(20, 21)
  end

  def test_alignment_pattern_detection_by_version
    # version one has no alignment patterns
    v1 = Qrio::QrMatrix.new(Array.new(441, false), 21, 21)
    assert_equal 1, v1.version

    (0...20).each do |c|
      refute v1.in_alignment_pattern?(c, c)
    end

    # construct versions 2 - 10 and verify alignment patterns
    [18, 22, 26, 30, 34, [22, 38], [24, 42], [26, 46], [28, 50]].each_with_index do |ap_centers, index|
      version = index + 2
      dimension = version * 4 + 17
      bits = Array.new(dimension * dimension, false)

      qr = Qrio::QrMatrix.new(bits, dimension, dimension)
      assert_equal version, qr.version

      qr.draw_alignment_patterns
      verify_alignment_centers(qr, *ap_centers)
      qr.raw_bytes.each do |byte|
        assert_equal 0, byte
      end
    end
  end

  def test_read_raw_bytes
    bytes = @qr.raw_bytes
    bytes.each_with_index do |byte, index|
      assert_equal index + 1, byte
    end
  end

  def test_unmask
    @qr[3,8] = false
    assert_equal 0, @qr.mask_pattern

    _, @masked = make_qr("masked0")
    @qr.unmask

    assert_equal @masked.raw_bytes, @qr.raw_bytes
  end

  private

  def verify_alignment_centers(qr, *centers)
    cols = *centers.dup
    rows = *centers.dup

    refute qr.in_alignment_pattern? 6, 6
    refute qr.in_alignment_pattern? qr.width - 7, 8
    refute qr.in_alignment_pattern? 8, qr.height - 7

    cols.each do |cy|
      rows.each do |cx|
        assert qr.in_alignment_pattern?(cx, cy), "(#{ cx }, #{ cy }) should be ap center (version #{ qr.version })"
        assert qr.in_alignment_pattern?(cx - 2, cy - 2)
        assert qr.in_alignment_pattern?(cx - 2, cy + 2)
        assert qr.in_alignment_pattern?(cx + 2, cy - 2)
        assert qr.in_alignment_pattern?(cx + 2, cy + 2)

        refute qr.in_alignment_pattern?(cx - 3, cy - 2), "(#{ cx - 3}, #{ cy - 2}) should be outside alignment pattern (version #{ qr.version })"
        refute qr.in_alignment_pattern?(cx - 2, cy - 3)
        refute qr.in_alignment_pattern?(cx + 3, cy + 2)
        refute qr.in_alignment_pattern?(cx + 2, cy + 3)
      end
    end
  end

  def fixture_content(filename)
    IO.read(File.expand_path("../fixtures/#{ filename }", __FILE__))
  end

  def make_qr(which)
    raw    = fixture_content("#{ which }.qr")
    data   = raw.strip.gsub(/\|/, '').split(/\n/)

    width  = data.first.length
    height = data.length
    off    = ' _.,'.split(//)

    bits  = data.join('').split(//).map{|s| ! off.include?(s) }
    [bits, Qrio::QrMatrix.new(bits, width, height)]
  end

  def bits_to_string(bits, width)
    chars = bits.map{|b| b ? '#' : ' ' }
    string = []
    while row = chars.slice!(0, width)
      break if row.nil? || row.empty?
      string << row.join
    end
    string << nil

    string.join("\n")
  end

end

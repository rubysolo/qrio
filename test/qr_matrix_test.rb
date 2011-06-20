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

    assert @qr.in_alignment_pattern?(16, 16)
    assert @qr.in_alignment_pattern?(18, 18)
    assert @qr.in_alignment_pattern?(20, 20)

    refute @qr.in_alignment_pattern?(15, 16)
    refute @qr.in_alignment_pattern?(16, 15)

    refute @qr.in_alignment_pattern?(21, 20)
    refute @qr.in_alignment_pattern?(20, 21)
  end

  def test_read_blocks
    blocks = @qr.blocks
    blocks.each_with_index do |block, index|
      assert_equal index + 1, block
    end
  end

  def test_unmask
    @qr[3,8] = false
    assert_equal 0, @qr.mask_pattern

    _, @masked = make_qr("masked0")
    @qr.unmask

    assert_equal @masked.blocks, @qr.blocks
  end

  private

  def make_qr(which)
    raw    = IO.read(File.expand_path("../fixtures/#{ which }.qr", __FILE__))
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

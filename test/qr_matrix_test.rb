require_relative '../lib/qrio'
require 'test/unit'

class TestQrMatrix < Test::Unit::TestCase
  def setup
    data = IO.read(__FILE__).split(/^__END__$/).last.
      strip.gsub(/\|/, '').split(/\n/)

    width  = data.first.length
    height = data.length
    off    = ' _.,'.split(//)
    bits   = data.join('').split(//).map{|s| ! off.include?(s) }

    @qr = Qrio::QrMatrix.new(bits, width, height)
  end

  def test_format_detection
    @qr[8, 1] = false
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
end

__END__

|##|##|##|#| *| $|$$|.$|$_| #|##|##|##|
|# |  |  |#| *|$ |$$|..|_$| #|  |  | #|
|# |##|# |#| *|  |__|.$|__| #| #|##| #|
|# |##|# |#| *|  |_ |.$|_ | #| #|##| #|
|# |##|# |#| *|. |$$|_.|$ | #| #|##| #|
|# |  |  |#| *|$.|$$|__| $| #|  |  | #|
|##|##|##|#| %| %| %| %| %| #|##|##|##|
|  |  |  | | *|..|  |_$|  |  |  |  |  |
|**|**|**|%|**|..| $|_$| $|**|**|**|**|
| $|$_| $| |$$| $|.$| $|__|$$|.$|__|  |
|$ |$_|$ |%|__|$ |$$|  |_$|  |..|__|$ |
|$ |$_|$ | |$_|  |..| $|__|  |..|$_|  |
| $|_ |  |%|_ |$ |. |$$|_ |$$|_$|$_|  |
|X |$ |. | |$$|_ | $|. |  |  |_$|  |$$|
|XX|$ |$.|%|  |$_|$$|..| $|..|__|  |__|
|XX|$ |$.| |$ |__|  |.$|  |..|__|$ |__|
|XX| $|..|%| $|$_| $|$$| #|##|##| $|__|
|  |  |  | | *| $|$_| $|$#|  | #|__| $|
|##|##|##|#| *|$ |$$|  |$#| #| #|__|  |
|# |  |  |#| *|  |__|$$|$#|  | #|$_|  |
|# |##|# |#| *| $|_ |  |$#|##|##|$$|  |
|# |##|# |#| *|. |$ |. |__|$$|$_|  |$_|
|# |##|# |#| *|$.|$$|..|__|$.|_$|  |__|
|# |  |  |#| *|..|  |$$| $|  |__| $|__|
|##|##|##|#| *|.$| $|..|$$|  |__|  |__|

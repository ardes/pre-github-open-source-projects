require File.dirname(__FILE__) + '/test_helper'
require 'ardes/uk_phone'

class UKPhoneTest < Test::Unit::TestCase
  
  def test_should_remove_cruft
    assert_equal '+44 79974678409', Ardes::UkPhone.new('   +44 79974678409     ').to_s
  end
  
  def test_should_be_identicial_when_phone_sane
    assert_equal '+44 79974678409', Ardes::UkPhone.new('+44 79974678409').to_s
  end
  
  def test_should_remove_parens
    assert_equal '0114 746 7840', Ardes::UkPhone.new('(0114) 746 7840').to_s
  end

  def test_should_validate_all_numbers_from_valid_uk_phone_numbers
    phones = File.open(File.dirname(__FILE__) + '/fixtures/valid_uk_phone_numbers.csv')
    phones.readline # skip the column headings
    CSV::Reader.parse(phones) do |phone|
      assert Ardes::UkPhone.new(phone).valid?
    end
  end
  
  def test_should_have_equality_for_objects_with_same_number
    assert_equal Ardes::UkPhone.new("01234569780"), Ardes::UkPhone.new("01234569780")
  end
  
  def test_should_have_equality_for_objects_with_same_number_including_cruft
    assert_equal Ardes::UkPhone.new("01234569780"), Ardes::UkPhone.new("  0  1 2 3  4569 78  0 ")
  end
  
  def test_should_have_equality_for_44_international_and_national_number
    assert_equal Ardes::UkPhone.new("+441234569780"), Ardes::UkPhone.new("01234569780")
  end
  
  def test_canonical_representation
    assert_equal '01234567890', Ardes::UkPhone.new("  +44  1234 567 890   ").canonical
  end
  
  def test_should_be_invalid_for_too_short_and_too_long_numbers
    assert (!Ardes::UkPhone.new('0123456789').valid?)
    assert (!Ardes::UkPhone.new('012345678901').valid?)
  end
  
  def test_should_be_invalid_for_non_uk_int_code
    assert (!Ardes::UkPhone.new('+417974678409').valid?)
  end
end

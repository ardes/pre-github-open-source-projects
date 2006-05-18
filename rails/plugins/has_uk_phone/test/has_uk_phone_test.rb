require File.dirname(__FILE__) + '/test_helper'
require 'ardes/test/has_uk_phone'
begin; require 'ardes/test/crud'; rescue MissingSourceFile; end

require File.dirname(__FILE__) + '/fixtures/uk_phone_holder'
class HasUkPhoneTest < Test::Unit::TestCase
  
  fixtures :uk_phone_holders
  
  test_has_uk_phone UkPhoneHolder, :phone, :phone2
  
  if defined?(Ardes::Test::Crud)
    test_crud UkPhoneHolder, :first, {:phone => Ardes::UkPhone.new('+447974668400'), :phone2 => nil}
  end
  
  def setup
    @obj = UkPhoneHolder.new
  end
  
  def test_should_have_data_expected_in_fixtures
    obj = UkPhoneHolder.find(1)
    assert_equal Ardes::UkPhone.new(uk_phone_holders(:first)[:phone]), obj.phone
    assert_equal nil, obj.phone2
    obj = UkPhoneHolder.find(2)
    assert_equal Ardes::UkPhone.new(uk_phone_holders(:second)[:phone]), obj.phone
    assert_equal Ardes::UkPhone.new(uk_phone_holders(:second)[:phone2]), obj.phone2
  end

  def test_should_be_valid_with_two_valid_phones
    @obj.phone  = Ardes::UkPhone.new('  +44 1142229988  ')
    @obj.phone2 = Ardes::UkPhone.new('(0114) 788 6566')
    assert @obj.valid?
  end
  
  def test_should_be_invalid_with_one_invalid_phone
    @obj.phone  = Ardes::UkPhone.new('+44 1142229988')
    @obj.phone2 = Ardes::UkPhone.new(' 0909393x992 ')
    assert(!@obj.valid?)
  end
  
  def test_should_be_valid_with_valid_phone_and_NULL_because_of_model_defenition
    @obj.phone  = Ardes::UkPhone.new('+44 1142229988')
    @obj.phone2 = nil
    assert(@obj.valid?)
  end
  
  def test_should_be_invalid_with_NULL_and_valid_phone_because_of_model_defenition
    @obj.phone2 = Ardes::UkPhone.new('+44 1142229988')
    assert(!@obj.valid?)
  end
end
require File.dirname(__FILE__) + '/../test_helper'
require 'ardes/test/active_record/crud'

class Ardes::TestCase::UkPostcodeModel < Test::Rails::TestCase
  
  fixtures :uk_postcode_models
  
  test_crud :uk_postcode_models, :first, {:postcode => UkPostcode.new('S11 8BH'), :postcode2 => UkPostcode.new('WC1A 1AA')}
  
  def setup
    @obj = UkPostcodeModel.new
  end
  
  def test_should_read_postcode_as_value_object
    fixture = uk_postcode_models(:first)
    object  = UkPostcodeModel.find(fixture.id)
    assert_equal UkPostcode.new(fixture.postcode), object.postcode
    assert_equal UkPostcode.new(fixture.postcode2), object.postcode2
  end
  
  def test_should_validate_S11_8BH
    @obj.postcode = UkPostcode.new('S11 8BH')
    assert @obj.valid_for_attributes?(:postcode)
  end
  
  def test_should_not_validate_XXX_XXX
    @obj.postcode = UkPostcode.new('XXX XXX')
    deny @obj.valid_for_attributes?(:postcode)
  end
  
  def test_should_be_valid_with_S11_8BH_and_WC1A_1AA
    @obj.postcode  = UkPostcode.new('S11 8BH')
    @obj.postcode2 = UkPostcode.new('WC1A 1AA')
    assert @obj.valid?
  end
  
  def test_should_be_invalid_with_S11_8BH_and_XXX_1AA
    @obj.postcode  = UkPostcode.new('S11 8BH')
    @obj.postcode2 = UkPostcode.new('XXX 1AA')
    deny @obj.valid?
  end
end

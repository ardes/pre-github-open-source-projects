require File.dirname(__FILE__) + '/test_helper'
require File.dirname(__FILE__) + '/test_has_uk_postcode_model.rb'
begin; require 'test_crud'; rescue MissingSourceFile; end

class HasUkPostcodeTest < Test::Unit::TestCase
  
  fixtures :test_has_uk_postcode_models
  
  if defined?(Test::Abstract::Crud)
    test_crud TestHasUkPostcodeModel, :first, {:postcode => UkPostcode.new('S11 8BH'), :postcode2 => UkPostcode.new('WC1A 1AA')}
  end
  
  def setup
    @obj = TestHasUkPostcodeModel.new
  end
  
  def test_should_read_postcode_as_value_object
    fixture = test_has_uk_postcode_models(:first)
    object  = TestHasUkPostcodeModel.find(fixture.id)
    assert_equal UkPostcode.new(fixture.postcode), object.postcode
    assert_equal UkPostcode.new(fixture.postcode2), object.postcode2
  end
  
  def test_should_validate_S11_8BH
    @obj.postcode = UkPostcode.new('S11 8BH')
    assert @obj.valid_for_attributes?(:postcode)
  end
  
  def test_should_not_validate_XXX_XXX
    @obj.postcode = UkPostcode.new('XXX XXX')
    assert(!@obj.valid_for_attributes?(:postcode))
  end
  
  def test_should_be_valid_with_S11_8BH_and_WC1A_1AA
    @obj.postcode  = UkPostcode.new('S11 8BH')
    @obj.postcode2 = UkPostcode.new('WC1A 1AA')
    assert @obj.valid?
  end
  
  def test_should_be_invalid_with_S11_8BH_and_XXX_1AA
    @obj.postcode  = UkPostcode.new('S11 8BH')
    @obj.postcode2 = UkPostcode.new('XXX 1AA')
    assert(!@obj.valid?)
  end
end

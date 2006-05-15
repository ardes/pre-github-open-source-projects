require File.dirname(__FILE__) + '/test_helper'
require File.dirname(__FILE__) + '/test_has_uk_postcode'
require File.dirname(__FILE__) + '/has_uk_postcode_test_model'
begin; require 'test_crud'; rescue MissingSourceFile; end

class HasUkPostcodeTest < Test::Unit::TestCase
  
  fixtures :has_uk_postcode_test_models
  
  test_has_uk_postcode HasUkPostcodeTestModel, :postcode, :postcode2
  
  if defined?(Test::Abstract::Crud)
    test_crud HasUkPostcodeTestModel, :first, {:postcode => UkPostcode.new('S11 8BH'), :postcode2 => UkPostcode.new(nil)}
  end
  
  def setup
    @obj = HasUkPostcodeTestModel.new
  end
  
  def test_should_have_data_expected_in_fixtures
    [:first, :second].each do |fixture|
      obj = HasUkPostcodeTestModel.find(has_uk_postcode_test_models(fixture)[:id])
      assert_equal UkPostcode.new(has_uk_postcode_test_models(fixture)[:postcode]), obj.postcode
      assert_equal UkPostcode.new(has_uk_postcode_test_models(fixture)[:postcode2]), obj.postcode2
    end
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
  
  def test_should_be_valid_with_S11_8BH_and_NULL_because_of_model_defenition
    @obj.postcode  = UkPostcode.new('S11 8BH')
    @obj.postcode2 = UkPostcode.new(nil)
    assert(@obj.valid?)
  end
  
  def test_should_be_invalid_with_NULL_and_S11_8BH_because_of_model_defenition
    @obj.postcode  = UkPostcode.new(nil)
    @obj.postcode2 = UkPostcode.new('S11 8BH')
    assert(!@obj.valid?)
  end
end
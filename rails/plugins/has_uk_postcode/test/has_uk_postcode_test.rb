require File.dirname(__FILE__) + '/test_helper'
require 'ardes/test/has_uk_postcode'
begin; require 'ardes/test/crud'; rescue MissingSourceFile; end

require File.dirname(__FILE__) + '/fixtures/uk_postcode_owner'

class HasUkPostcodeTest < Test::Unit::TestCase
  
  fixtures :uk_postcode_owners
  
  test_has_uk_postcode UkPostcodeOwner, :postcode, :postcode2
  
  if defined?(Ardes::Test::Crud)
    test_crud UkPostcodeOwner, :first, {:postcode => Ardes::UkPostcode.new('S11 8BH'), :postcode2 => nil}
  end
  
  def setup
    @obj = UkPostcodeOwner.new
  end
  
  def test_should_have_data_expected_in_fixtures
    [:first, :second].each do |fixture|
      obj = UkPostcodeOwner.find(uk_postcode_owners(fixture)[:id])
      assert_equal Ardes::UkPostcode.new(uk_postcode_owners(fixture)[:postcode]), obj.postcode
      unless obj.postcode2.nil? 
        assert_equal Ardes::UkPostcode.new(uk_postcode_owners(fixture)[:postcode2]), obj.postcode2
      end
    end
  end

  def test_should_be_valid_with_S11_8BH_and_WC1A_1AA
    @obj.postcode  = Ardes::UkPostcode.new('S11 8BH')
    @obj.postcode2 = Ardes::UkPostcode.new('WC1A 1AA')
    assert @obj.valid?
  end
  
  def test_should_be_invalid_with_S11_8BH_and_XXX_1AA
    @obj.postcode  = Ardes::UkPostcode.new('S11 8BH')
    @obj.postcode2 = Ardes::UkPostcode.new('XXX 1AA')
    assert(!@obj.valid?)
  end
  
  def test_should_be_valid_with_S11_8BH_and_NULL_because_of_model_defenition
    @obj.postcode  = Ardes::UkPostcode.new('S11 8BH')
    @obj.postcode2 = nil
    assert(@obj.valid?)
  end
  
  def test_should_be_invalid_with_NULL_and_S11_8BH_because_of_model_defenition
    @obj.postcode2 = Ardes::UkPostcode.new('S11 8BH')
    assert(!@obj.valid?)
  end
end
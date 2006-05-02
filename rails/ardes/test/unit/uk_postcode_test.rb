require File.dirname(__FILE__) + '/../test_helper'

class Ardes::TestCase::UkPostcodeModel < Test::Rails::TestCase
  
  def setup
    @obj = UkPostcodeModel.new
  end
  
  def test_should_be_upcase_after_validation
    @obj.postcode = 's11 1bh'
    @obj.valid?
    assert_equal 'S11 1BH', @obj.postcode
  end
end

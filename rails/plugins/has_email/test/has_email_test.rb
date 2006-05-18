require File.dirname(__FILE__) + '/test_helper'
require 'ardes/test/has_email'
begin; require 'ardes/test/crud'; rescue MissingSourceFile; end

require File.dirname(__FILE__) + '/fixtures/email_holder'
class HasEmailTest < Test::Unit::TestCase
  
  fixtures :email_holders
  
  test_has_email EmailHolder, :email, :email2
  
  if defined?(Ardes::Test::Crud)
    test_crud EmailHolder, :first, {:email => Ardes::Email.new('jimmy@no-email.net'), :email2 => nil}
  end
  
  def setup
    @obj = EmailHolder.new
  end
  
  def test_should_have_data_expected_in_fixtures
    obj = EmailHolder.find(1)
    assert_equal Ardes::Email.new(email_holders(:first)[:email]), obj.email
    assert_equal nil, obj.email2
    obj = EmailHolder.find(2)
    assert_equal Ardes::Email.new(email_holders(:second)[:email]), obj.email
    assert_equal Ardes::Email.new(email_holders(:second)[:email2]), obj.email2
  end

  def test_should_be_valid_with_two_valid_emails
    @obj.email  = Ardes::Email.new('   any@boombip.net  ')
    @obj.email2 = Ardes::Email.new('    jimbo@me.com    ')
    assert @obj.valid?
  end
  
  def test_should_be_invalid_with_one_invalid_phone
    @obj.email  = Ardes::Email.new(' any  @ gibboon.comm ')
    @obj.email2 = Ardes::Email.new(' 1@1 ')
    assert(!@obj.valid?)
  end
  
  def test_should_be_valid_with_valid_phone_and_NULL_because_of_model_defenition
    @obj.email  = Ardes::Email.new('ian@ardes.com')
    assert(@obj.valid?)
  end
  
  def test_should_be_invalid_with_NULL_and_valid_phone_because_of_model_defenition
    @obj.email2 = Ardes::Email.new('ian@ardes.com')
    assert(!@obj.valid?)
  end
end
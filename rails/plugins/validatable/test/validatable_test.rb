require File.dirname(__FILE__) + '/test_helper'
require 'ardes/test/validatable'

require 'ardes/validatable'

class ValidatableTest < Test::Unit::TestCase
  class TestObject
    def method_missing(*args)
      "foo"
    end
    include Ardes::Validatable
    attr_accessor :name, :age

    validates_format_of :name, :with => /ian/
    validates_presence_of :age
  end
  
  test_validatable TestObject, {:name => 'ian', :age => 34}, {:name => 'dork', :age => nil}

  def test_method_missing_should_call_existing_when_no_responder_found
    obj = TestObject.new
    assert_equal "foo", obj.foo
  end
end
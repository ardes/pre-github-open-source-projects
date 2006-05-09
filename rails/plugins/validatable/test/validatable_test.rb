require File.dirname(__FILE__) + '/test_helper'
require File.dirname(__FILE__) + '/test_validatable'
require File.dirname(__FILE__) + '/test_story_validatable'

require 'validatable'

class ValidatableTest < Test::Unit::TestCase
  class TestObject
    include Validatable
    attr_accessor :name, :age

    validates_format_of :name, :with => /ian/
    validates_presence_of :age
  end
  
  test_story_validatable TestObject, {:name => 'ian', :age => 34}, {:name => 'dork', :age => nil}
  test_validatable TestObject, {:name => 'ian', :age => 34}
end

class ValidatableTestForMethodMissing < Test::Unit::TestCase
  class TestObject
    attr_accessor :name, :age
    def method_missing(*args)
      "foo"
    end
    include Validatable
  end
  
  test_validatable TestObject, {:name => 'ian', :age => 34}
  
  def test_method_missing_should_call_existing_when_no_responder_found
    obj = TestObject.new
    assert_equal "foo", obj.foo
  end
end
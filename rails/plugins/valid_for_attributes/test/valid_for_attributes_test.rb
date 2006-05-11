require File.dirname(__FILE__) + '/test_helper'

class ValidForAttributesTest < Test::Unit::TestCase
  class TestObject < ActiveRecord::Base
    acts_as_tableless :thing, :foo, :bar
    validates_presence_of :thing, :foo, :bar
  end
  
  def test_should_not_be_valid_on_invalid_obj
    o = TestObject.new
    assert(!o.valid?)
  end
  
  def test_should_not_validate_invalid_obj
    o = TestObject.new
    o.thing = 'thing'
    o.foo = 'foo'
    assert(o.valid_for_attributes?(:foo, :thing))
    assert(!o.valid?)
    assert(!o.valid_for_attributes?(:bar))
    assert(!o.valid?)
  end
  
  def test_valid_for_attributes_for_each_valid_attribute
    [:foo, :bar, :thing].each do |a|
      o = TestObject.new()
      o.send(a.to_s + "=", "summat")
      assert o.valid_for_attributes?(a)
    end
  end
end
require File.dirname(__FILE__) + '/test_helper'
require 'ardes/test/acts_as_tableless'

class ActsAsTablelessTest < Test::Unit::TestCase
  class TestObject < ActiveRecord::Base
    acts_as_tableless do
      column :age, :integer, :null => true
      column :name, :string, :limit => 20, :default => 'anonymous'
      column :rating, :integer, :null => false, :default => 10
    end
    validates_presence_of :age
  end
  
  test_acts_as_tableless TestObject
  
  def test_should_have_defaults_correpsonding_to_column_definition
    obj = TestObject.new
    assert_equal 'anonymous', obj.name
    assert_equal 10, obj.rating
    assert_equal nil, obj.age
  end

  def test_should_have_types_corresponding_to_column_definition
    obj = TestObject.new
    assert_kind_of String, obj.name
    assert_kind_of Integer, obj.rating
    assert_kind_of NilClass, obj.age
  end
  
  def test_should_allow_validation
    obj = TestObject.new
    assert(!obj.valid?)
    obj.age = 20
    assert obj.valid?
  end
end

class ActsAsTablelessTestMinimumColDefs < Test::Unit::TestCase
  
  class TestObject < ActiveRecord::Base
    acts_as_tableless :name, :age
  end

  test_acts_as_tableless TestObject
  
  def test_should_accept_values_when_initialized_with_column_names_only
    obj = TestObject.new
    obj.name = 'frank'
    obj.age = 20
    assert_equal 'frank', obj.name
    assert_equal 20, obj.age
  end
end

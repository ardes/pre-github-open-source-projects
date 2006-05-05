require File.dirname(__FILE__) + '/../test_helper'
require 'ardes/test/active_record/acts/tableless'

class NoTable < ActiveRecord::Base
  acts_as_tableless do
    column :age, :integer, :null => true
    column :name, :string, :limit => 20, :default => 'anonymous'
    column :rating, :integer, :null => false, :default => 10
  end

  validates_presence_of :age
end

class Ardes::TestCase::ActsAsTablelessNoTable < Test::Rails::TestCase
  test_acts_as_tableless :no_table
  
  def test_should_have_defaults_correpsonding_to_column_definition
    obj = NoTable.new
    assert_equal 'anonymous', obj.name
    assert_equal 10, obj.rating
    assert_equal nil, obj.age
  end

  def test_should_have_types_corresponding_to_column_definition
    obj = NoTable.new
    assert_kind_of String, obj.name
    assert_kind_of Integer, obj.rating
    assert_kind_of NilClass, obj.age
  end
  
  def test_should_allow_validation
    obj = NoTable.new
    deny obj.valid?
    obj.age = 20
    assert obj.valid?
  end
end

#=============

class InitWithColumnNamesNoTable < ActiveRecord::Base
  acts_as_tableless :name, :age
end

class Ardes::TestCase::ActsAsTablelessInitWithColumnNamesNoTable < Test::Rails::TestCase
  test_acts_as_tableless :init_with_column_names_no_table
  
  def test_should_accept_values_when_initialized_with_column_names_only
    obj = InitWithColumnNamesNoTable.new
    obj.name = 'frank'
    obj.age = 20
    assert_equal 'frank', obj.name
    assert_equal 20, obj.age
  end
end
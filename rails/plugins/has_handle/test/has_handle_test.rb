require File.dirname(__FILE__) + '/test_helper'
require File.dirname(__FILE__) + '/test_has_handle'
require File.dirname(__FILE__) + '/has_handle_test_model.rb'
begin; require 'test_crud'; rescue MissingSourceFile; end

class HasHandleTest < Test::Unit::TestCase
  fixtures :has_handle_test_models
  test_has_handle HasHandleTestModel
  
  if defined?(Test::Abstract::Crud)
    test_crud HasHandleTestModel, :first, {:handle => 'third'}
  end
end

#-----
class HasHandleOtherColumnTestModel < ActiveRecord::Base
  has_handle :other
end

class HasHandleTestOtherColumn < Test::Unit::TestCase
  fixtures :has_handle_other_column_test_models
  test_has_handle HasHandleOtherColumnTestModel
  
  if defined?(Test::Abstract::Crud)
    test_crud HasHandleOtherColumnTestModel, :first, {:other => 'third'}
  end
end

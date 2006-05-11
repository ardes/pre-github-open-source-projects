require File.dirname(__FILE__) + '/test_helper'
require File.dirname(__FILE__) + '/test_has_handle'
require File.dirname(__FILE__) + '/test_has_handle_model.rb'
begin; require 'test_crud'; rescue MissingSourceFile; end

class HasHandleTest < Test::Unit::TestCase
  fixtures :test_has_handle_models
  test_has_handle TestHasHandleModel
  
  if defined?(Test::Abstract::Crud)
    test_crud TestHasHandleModel, :first, {:handle => 'third'}
  end
end

#-----
class TestHasHandleOtherColumnModel < ActiveRecord::Base
  has_handle :other
end

class HasHandleTestOtherColumn < Test::Unit::TestCase
  fixtures :test_has_handle_other_column_models
  test_has_handle TestHasHandleOtherColumnModel
  
  if defined?(Test::Abstract::Crud)
    test_crud TestHasHandleOtherColumnModel, :first, {:other => 'third'}
  end
end

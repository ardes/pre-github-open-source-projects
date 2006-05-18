require File.dirname(__FILE__) + '/test_helper'
require 'ardes/test/has_handle'
begin; require 'ardes/test/crud'; rescue MissingSourceFile; end

require File.dirname(__FILE__) + '/fixtures/handle_model'
class HasHandleTest < Test::Unit::TestCase
  fixtures :handle_models
  test_has_handle HandleModel, [1, 'first'], [2, 'second']
  
  if defined?(Ardes::Test::Crud)
    test_crud HandleModel, :first, {:handle => 'third'}
  end
end

require File.dirname(__FILE__) + '/fixtures/handle_other_column_model'
class HasHandleTestOtherColumn < Test::Unit::TestCase
  fixtures :handle_other_column_models
  test_has_handle HandleOtherColumnModel, [1, 'first'], [2, 'second'], [666, 'six_hundred_and_66']
  
  if defined?(Ardes::Test::Crud)
    test_crud HandleOtherColumnModel, :first, {:other => 'third'}
  end
end

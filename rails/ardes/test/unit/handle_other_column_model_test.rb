require File.dirname(__FILE__) + '/../test_helper'
require 'ardes/test/active_record/has/handle'
require 'ardes/test/active_record/crud'

class Ardes::TestCase::HandleOtherColumnModel < Test::Rails::TestCase
  fixtures :handle_other_column_models
  
  test_has_handle :handle_other_column_model
  test_crud :handle_other_column_model, :first, {:other => 'third'}
end

require File.dirname(__FILE__) + '/../test_helper'
require 'ardes/test/active_record/has/handle'
require 'ardes/test/active_record/crud'

class Ardes::TestCase::HandleModel < Test::Rails::TestCase
  fixtures :handle_models
  test_has_handle :handle_model
  test_crud :handle_model, :first, {:handle => 'third'}
end

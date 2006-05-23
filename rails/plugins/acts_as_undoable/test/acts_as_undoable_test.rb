require File.dirname(__FILE__) + '/test_helper'

class ActsAsUndoableTest < Test::Unit::TestCase
  
  def test_models_should_have_same_undo_manager
    assert_equal Car.undo_manager, CarPart.undo_manager
  end
  
end

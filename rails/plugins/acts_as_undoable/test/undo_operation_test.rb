require File.dirname(__FILE__) + '/test_helper'
require 'ardes/undo_operation'

# Fixtures define a state whereby
#   1. car 1 created with car_part 1
#   2. car 1 updated and car_part 2 added
#   3. car 1 destroyed (along with dependent parts)
#   4. UNDO of 3
# So Car(1) is exists and is version 2 at start of tests.
class UndoOperationTest < Test::Unit::TestCase
  fixtures :car_undo_changes, :car_undo_operations, :cars, :car_versions, :car_parts, :car_part_versions

  def test_should_create_correct_class
    operation_class = Ardes::UndoOperation.class_for(:car)
    assert_equal 'CarUndoOperation', operation_class.name
    assert operation_class.reflect_on_association(:changes)
  end
  
  def test_find_undone_first
    CarUndoOperation.update_all(["undone = ?", true])
    assert_equal car_undo_operations(:op1), CarUndoOperation.find(:undone, :first)
  end
  
  def test_find_undone_last
    CarUndoOperation.update_all(["undone = ?", true])
    assert_equal car_undo_operations(:op3), CarUndoOperation.find(:undone, :last)
  end
  
  def test_find_undone_all
    CarUndoOperation.update_all(["undone = ?", true])
    assert_equal [car_undo_operations(:op1), car_undo_operations(:op2), car_undo_operations(:op3)], CarUndoOperation.find(:undone, :all)
  end
  
  def test_find_undone_to_operation2
    CarUndoOperation.update_all(["undone = ?", true])
    assert_equal [car_undo_operations(:op1), car_undo_operations(:op2)], CarUndoOperation.find(:undone, :to => car_undo_operations(:op2)[:id])
  end
  
  def test_find_not_undone_first
    CarUndoOperation.update_all(["undone = ?", false])
    assert_equal car_undo_operations(:op3), CarUndoOperation.find(:not_undone, :first)
  end
  
  def test_find_not_undone_last
    CarUndoOperation.update_all(["undone = ?", false])
    assert_equal car_undo_operations(:op1), CarUndoOperation.find(:not_undone, :last)
  end
  
  def test_find_not_undone_all
    CarUndoOperation.update_all(["undone = ?", false])
    assert_equal [car_undo_operations(:op3), car_undo_operations(:op2), car_undo_operations(:op1)], CarUndoOperation.find(:not_undone, :all)
  end
  
  def test_find_not_undone_to_operation2
    CarUndoOperation.update_all(["undone = ?", false])
    assert_equal [car_undo_operations(:op3), car_undo_operations(:op2)], CarUndoOperation.find(:not_undone, :to => car_undo_operations(:op2)[:id])
  end
  
  def test_find_all_default_args
    assert_equal [car_undo_operations(:op2), car_undo_operations(:op1)], CarUndoOperation.find(:not_undone)
    assert_equal [car_undo_operations(:op3)], CarUndoOperation.find(:undone)
  end
  
  def test_find_argument_error
    assert_raises(ArgumentError) { CarUndoOperation.find :undone, :klingon }
  end
  
  def test_should_have_changes_association
    assert_equal [CarUndoChange.find(1), CarUndoChange.find(2)], CarUndoOperation.find(1).changes
  end
  
  def test_should_perform_redo_then_undo_of_destroy
    assert car_undo_operations(:op3).redo
    assert_raise(ActiveRecord::RecordNotFound) { Car.find(cars(:nissan)[:id]) }
    assert_raise(ActiveRecord::RecordNotFound) { CarPart.find(car_parts(:nissan_wheels)[:id]) }
    assert_raise(ActiveRecord::RecordNotFound) { CarPart.find(car_parts(:nissan_roof)[:id]) }
    
    assert car_undo_operations(:op3).undo
    car = Car.find(cars(:nissan)[:id])
    assert_equal 'nissan v2', car.name
    assert_equal 'wheels', car.car_parts.first.name
    assert_equal 'roof', car.car_parts.last.name
  end

  def test_should_perform_undo_and_redo_of_update_and_create
    assert car_undo_operations(:op2).undo
    car = Car.find(cars(:nissan)[:id])
    assert_equal 1, car.version
    assert_equal 1, car.car_parts.find(car_parts(:nissan_wheels)[:id]).version
    assert_raise(ActiveRecord::RecordNotFound) { car.car_parts.find(car_parts(:nissan_roof)[:id]) }
    
    assert car_undo_operations(:op1).undo
    assert_raise(ActiveRecord::RecordNotFound) { Car.find(cars(:nissan)[:id]) }
    assert_raise(ActiveRecord::RecordNotFound) { CarPart.find(car_parts(:nissan_wheels)[:id]) }

    assert car_undo_operations(:op2).redo # should redo operation1 as well
    car = Car.find(cars(:nissan)[:id])
    assert_equal 2, car.version
    assert_equal 1, car.car_parts.find(car_parts(:nissan_wheels)[:id]).version
    assert_equal 1, car.car_parts.find(car_parts(:nissan_roof)[:id]).version
  end
  
  def test_should_destroy_changes_when_operation_destroyed 
    CarUndoOperation.destroy_all
    assert_equal 0, CarUndoOperation.count
    assert_equal 0, CarUndoChange.count
  end
  
  def test_should_delete_currently_undone_changes_when_changes_pushed
    assert_equal 1, CarUndoOperation.count(["undone = ?", true])
    CarUndoOperation.push([CarUndoChange.new])
    assert_equal 0, CarUndoOperation.count(["undone = ?", true])
  end
end

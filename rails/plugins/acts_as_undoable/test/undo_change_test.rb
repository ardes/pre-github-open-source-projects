require File.dirname(__FILE__) + '/test_helper'
require 'ardes/undo_change'

# Fixtures define a state whereby
#   1. car 1 created with car_part 1
#   2. car 1 updated and car_part 2 added
#   3. car 1 destroyed (along with dependent parts)
#   4. UNDO of 3
# So Car(1) is exists and is version 2 at start of tests.
class UndoChangeTest < Test::Unit::TestCase
  fixtures :car_undo_changes, :car_undo_operations, :cars, :car_versions, :car_parts, :car_part_versions
  
  def test_should_create_correct_class
    change_class = Ardes::UndoChange.class_for(CarUndoOperation)
    assert_equal 'CarUndoChange', change_class.name
    assert change_class.reflect_on_association(:operation)
  end
    
  def test_should_have_operation_association
    assert_equal CarUndoOperation.find(1), CarUndoChange.find(1).operation
  end

  def test_should_give_appropriate_ch_desc
    assert_equal 'create car part: 1', car_undo_changes(:op1_ch1).change_desc
    assert_equal 'create car: 1', car_undo_changes(:op1_ch2).change_desc
  end
  
  def test_should_perform_redo_then_undo_of_destroy
    assert car_undo_changes(:op3_ch1).redo
    assert car_undo_changes(:op3_ch2).redo
    assert car_undo_changes(:op3_ch3).redo
    assert_raise(ActiveRecord::RecordNotFound) { Car.find(cars(:nissan)[:id]) }
    assert_raise(ActiveRecord::RecordNotFound) { CarPart.find(car_parts(:nissan_wheels)[:id]) }
    assert_raise(ActiveRecord::RecordNotFound) { CarPart.find(car_parts(:nissan_roof)[:id]) }
    
    assert car_undo_changes(:op3_ch1).undo
    assert car_undo_changes(:op3_ch2).undo
    assert car_undo_changes(:op3_ch3).undo
    car = Car.find(cars(:nissan)[:id])
    assert_equal 'nissan v2', car.name
    assert_equal 'wheels', car.car_parts.first.name
    assert_equal 'roof', car.car_parts.last.name
  end
  
  def test_should_perform_undo_and_redo_of_update_and_create
    assert car_undo_changes(:op2_ch1).undo
    assert car_undo_changes(:op2_ch2).undo
    car = Car.find(cars(:nissan)[:id])
    assert_equal 1, car.version
    assert_equal 1, car.car_parts.find(car_parts(:nissan_wheels)[:id]).version
    assert_raise(ActiveRecord::RecordNotFound) { car.car_parts.find(car_parts(:nissan_roof)[:id]) }
    
    assert car_undo_changes(:op1_ch1).undo
    assert car_undo_changes(:op1_ch2).undo
    assert_raise(ActiveRecord::RecordNotFound) { Car.find(cars(:nissan)[:id]) }
    assert_raise(ActiveRecord::RecordNotFound) { CarPart.find(car_parts(:nissan_wheels)[:id]) }

    assert car_undo_changes(:op1_ch1).redo
    assert car_undo_changes(:op1_ch2).redo
    car = Car.find(cars(:nissan)[:id])
    assert_equal 1, car.version
    assert_equal 1, car.car_parts.find(car_parts(:nissan_wheels)[:id]).version
    assert_raise(ActiveRecord::RecordNotFound) { car.car_parts.find(car_parts(:nissan_roof)[:id]) }

    assert car_undo_changes(:op2_ch1).redo
    assert car_undo_changes(:op2_ch2).redo
    car = Car.find(cars(:nissan)[:id])
    assert_equal 2, car.version
    assert_equal 1, car.car_parts.find(car_parts(:nissan_wheels)[:id]).version
    assert_equal 1, car.car_parts.find(car_parts(:nissan_roof)[:id]).version
  end
end

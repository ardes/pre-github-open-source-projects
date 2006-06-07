require File.dirname(__FILE__) + '/test_helper'
require 'ardes/undo_manager'

# Fixtures define a state whereby
#   1. car 1 created with car_part 1
#   2. car 1 updated and car_part 2 added
#   3. car 1 destroyed (along with dependent parts)
#   4. UNDO of 3
# So Car(1) exists with two parts and is version 2 at start of tests.
class UndoManagerTest < Test::Unit::TestCase
  fixtures  :car_undo_changes, :car_undo_operations, :cars, :car_versions, :car_parts, :car_part_versions,
            :foos, :foo_versions, :foo_undo_operations, :foo_undo_changes

  def setup
    @car_manager = Ardes::UndoManager.for(:car)
    @foo_manager = Ardes::UndoManager.for(:foo) # foo is undoing all operations (acts_as_undoable :foo, :all)
  end
  
  def test_should_have_correct_undoables
    assert_equal [car_undo_operations(:op2), car_undo_operations(:op1)], @car_manager.undoables
    assert(@car_manager.undo)
    assert_equal [car_undo_operations(:op1)], @car_manager.undoables
    assert(@car_manager.undo(:all))
    assert_equal [], @car_manager.undoables
    assert(@car_manager.redo(:all))
    assert_equal [car_undo_operations(:op3), car_undo_operations(:op2), car_undo_operations(:op1)], @car_manager.undoables
  end
  
  def test_should_have_correct_redoables
    assert_equal [car_undo_operations(:op3)], @car_manager.redoables
    assert(@car_manager.redo)
    assert_equal [], @car_manager.redoables    
    assert(@car_manager.undo(:all))
    assert_equal [car_undo_operations(:op1), car_undo_operations(:op2), car_undo_operations(:op3)], @car_manager.redoables
  end
  
  def test_nested_undoable
    car_1_id = car_2_id = car_part_1_id = nil
    op = @car_manager.execute do |operation|
      c = Car.new(:name => 'ford')
      c.car_parts << CarPart.new(:name => 'gearstick')
      c.save
      car_1_id = c.id
      car_part_1_id = c.car_parts.first.id
      @car_manager.execute do
        car_2_id = Car.create(:name => c.name + " II").id
      end
      operation[:description] = 'two fords and a gearstick'
    end
    
    assert_equal 3, op.class.count
    assert_equal 'two fords and a gearstick', op.description
    assert_equal false, op.undone
    
    assert_equal "create car part: #{car_part_1_id}", op.changes[0].change_desc
    assert_equal "create car: #{car_1_id}", op.changes[1].change_desc
    assert_equal "create car: #{car_2_id}", op.changes[2].change_desc
  end
  
  def test_set_description_in_execute_params
    op = @car_manager.execute(:description => 'foo') do
      Car.create(:name => 'foocar')
    end
    assert_equal 'foo', op.description
  end
  
  def test_set_description_in_block
    op = @car_manager.execute do |operation|
      Car.create(:name => 'foocar')
      operation[:description] = 'foo'
    end
    assert_equal 'foo', op.description
  end
  
  def test_set_description_by_string_in_execute_params
    op = @car_manager.execute('foo') do
      Car.create(:name => 'foocar')
    end
    assert_equal 'foo', op.description
  end
  
  def test_broken_undoable_should_reset_manager
    CarUndoOperation.destroy_all
    Car.destroy_all

    @car_manager.execute do
      Car.create(:name => 'foocar')
      raise 'Boom!'
    end
  
  rescue
    assert_equal 0, Car.count
    assert_equal 0, @car_manager.undoables.size
    
    @car_manager.execute do
      Car.create(:name => 'barcar')
    end
    
    assert_equal 1, Car.count
    assert_equal 1, @car_manager.undoables.size
    assert_equal 1, @car_manager.undoables.first.changes.size
  end
  
  def test_deeply_nested_broken_undoable_should_reset_manager
    CarUndoOperation.destroy_all
    Car.destroy_all
    
    @car_manager.execute do
      Car.create(:name => 'foocar1')
      @car_manager.execute do
        Car.create(:name => 'foocar2')
        @car_manager.execute do
          Car.create(:name => 'foocar3')
          raise 'Boom!'
        end
      end
    end

  rescue
    assert_equal 0, Car.count
    assert_equal 0, @car_manager.undoables.size
    
    @car_manager.execute do
      Car.create(:name => 'barcar')
    end
    
    assert_equal 1, Car.count
    assert_equal 1, @car_manager.undoables.size
    assert_equal 1, @car_manager.undoables.first.changes.size
  end

  def test_without_undo
    CarUndoOperation.destroy_all
    Car.destroy_all

    with_undo_id = nil
    @car_manager.execute do
      with_undo_id = Car.create(:name => 'with_undo').id
      Car.without_undo do
        Car.create(:name => 'without_undo')
      end
    end
    
    assert_equal 2, Car.count
    assert_equal 1, @car_manager.undoables.size
    assert_equal "create car: #{with_undo_id}", @car_manager.undoables.first.description
    assert_equal 1, @car_manager.undoables.first.changes.size
    assert_equal with_undo_id, @car_manager.undoables.first.changes.first.obj_id
  end
  
  def test_acts_as_undoable_all
    id = Foo.create(:name => 'foo1').id
    assert_equal "create foo: #{id}", @foo_manager.undoables(:first).description
    Foo.find(id).update_attributes(:name => 'foo2')                  
    assert_equal "update foo: #{id}", @foo_manager.undoables(:first).description
    Foo.destroy(id)
    assert_equal "destroy foo: #{id}", @foo_manager.undoables(:first).description
  end
  
  def test_without_undo_with_acts_as_undoable_all
    Foo.without_undo { Foo.create(:name => 'foo')}
    assert_equal 1, Foo.count
    assert_equal 0, @foo_manager.undoables.size
  end
end

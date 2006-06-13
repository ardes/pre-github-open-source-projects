require File.dirname(__FILE__) + '/test_helper'
require 'ardes/test/acts_as_undoable'
begin; require 'ardes/test/crud'; rescue MissingSourceFile; end  

class ActsAsUndoableCarPartTest < Test::Unit::TestCase
  fixtures :car_parts, :car_part_versions
  
  if defined?(Ardes::Test::Crud)
    test_crud CarPart, :nissan_wheels, {:name => 'new_part', :position => 999, :car_id => nil}
  end
  
  test_acts_as_undoable CarPart, :nissan_wheels, {:name => 'new_part2', :car_id => 77}
end

class ActsAsUndoableUseCaseTest < Test::Unit::TestCase
  fixtures  :car_undo_changes, :car_undo_operations, :cars, :car_versions, :car_parts, :car_part_versions,
            :foos, :foo_versions, :foo_undo_operations, :foo_undo_changes
  
  def setup
    @car_manager = Ardes::UndoManager.for :car
    @foo_manager = Ardes::UndoManager.for :foo
  end 
  
  def test_models_should_have_correct_undo_manager
    assert_same @car_manager, Car.undo_manager
    assert_same Car.undo_manager, CarPart.undo_manager
    assert_same @foo_manager, Foo.undo_manager
  end
  
  def test_use_case_cars
    Car.destroy_all
    CarUndoOperation.destroy_all
    
    car = nil
    
    create_car = @car_manager.execute do |opts| 
      car = Car.new(:name => 'Car')
      (1..4).each {|i| car.car_parts << CarPart.new(:name => "Wheel #{i}")}
      opts[:description] = "Car with 4 wheels created"
      car.save
    end
    
    assert_equal [create_car],  @car_manager.undoables
    assert_equal [],            @car_manager.redoables
            
    change_car = @car_manager.execute("Lost a wheel and gained a fender") do |opts| 
      wheel = CarPart.find_by_car_id_and_name(car.id, 'Wheel 3')
      wheel.destroy
      car.car_parts << CarPart.new(:name => 'Fender')
      car.name = "Changed Car"
      car.undoable { car.save } # test a nested undoable 
    end
    
    assert_equal [change_car, create_car],  @car_manager.undoables
    assert_equal [],                        @car_manager.redoables
    
    # Check the database before undo.  We should have ChangedCar with Wheels 1,2,4 and a Fender
    assert_equal 'Changed Car', Car.find_first.name
    assert_equal ['Wheel 1', 'Wheel 2', 'Wheel 4', 'Fender'], Car.find_first.car_parts.collect {|p| p.name}
    
    # Undo change_car
    change_car.undo
    
    assert_equal [create_car], @car_manager.undoables
    assert_equal [change_car], @car_manager.redoables
    
    # Check the database to make sure we're back with our car before the change
    assert_equal 'Car', Car.find_first.name
    assert_equal ['Wheel 1', 'Wheel 2', 'Wheel 3', 'Wheel 4'], Car.find_first.car_parts.collect {|p| p.name}
    
    # Undo create_car
    create_car.undo
    
    assert_equal [],                        @car_manager.undoables
    assert_equal [create_car, change_car],  @car_manager.redoables
    
    # Check the database to make sure we got nothin!
    assert_equal [], Car.find_all
    
    # Redo change_car (which will also redo create_car in order to do this)
    change_car.redo
    assert_equal [change_car, create_car],  @car_manager.undoables
    assert_equal [],                        @car_manager.redoables
    
    # Check the database before undo.  We should have ChangedCar with Wheels 1,2,4 and a Fender
    assert_equal 'Changed Car', Car.find_first.name
    assert_equal ['Wheel 1', 'Wheel 2', 'Wheel 4', 'Fender'], Car.find_first.car_parts.collect {|p| p.name}
  end
  
  # we want this test to run first on an empty table
  def test_use_case_foos
    Foo.undo_all = true
    
    foo1_id = Foo.create(:name => 'foo').id
    Foo.find(foo1_id).update_attributes(:name => 'MOO')
    foo_change = Foo.undo_manager.last_operation # remeber this point
    foo2_id = Foo.create(:name => 'bar').id
    foo_destroy_all = Foo.undoable('destroy all foos') { Foo.destroy_all }
    
    # check there's no foos, and that there's 4 undoables in the right order
    assert_equal [], Foo.find_all
    assert_equal ['destroy all foos', "create foo: #{foo2_id}", "update foo: #{foo1_id}", "create foo: #{foo1_id}"],
                 @foo_manager.undoables.collect {|op| op.description}
    
    # now undo foo_change (undoing all ops in between) and check
    foo_change.undo
    
    assert_equal ['foo'], Foo.find_all.collect {|r| r.name}
    assert_equal ["create foo: #{foo1_id}"], @foo_manager.undoables.collect {|op| op.description}
    assert_equal ["update foo: #{foo1_id}", "create foo: #{foo2_id}", "destroy all foos"],
                 @foo_manager.redoables.collect {|op| op.description}
    
    # redo twice (using different idioms) and check
    Foo.undo_manager.redo
    @foo_manager.redo
    assert_equal ['MOO', 'bar'], Foo.find_all.collect {|r| r.name}
    assert_equal ["create foo: #{foo2_id}", "update foo: #{foo1_id}", "create foo: #{foo1_id}"],
                 @foo_manager.undoables.collect {|op| op.description}
    assert_equal ['destroy all foos'], @foo_manager.redoables.collect {|op| op.description}
    
    # make new change (this will destory the currently undone foo_destroy_all operation) and check
    foo3_id = Foo.create(:name => 'woooo').id
    assert_equal ['MOO', 'bar', 'woooo'], Foo.find_all.collect {|r| r.name}
    assert_equal ["create foo: #{foo3_id}", "create foo: #{foo2_id}", "update foo: #{foo1_id}", "create foo: #{foo1_id}"],
                 @foo_manager.undoables.collect {|op| op.description}
    assert_equal [], @foo_manager.redoables.collect {|op| op.description}
    
    # try and undo the stale foo_destroy_all operation, it will raise an error and do nothing the the db
    assert_raise(Ardes::UndoOperation::Stale) { foo_destroy_all.undo }
    assert_equal ['MOO', 'bar', 'woooo'], Foo.find_all.collect {|r| r.name}    
    assert_equal ["create foo: #{foo3_id}", "create foo: #{foo2_id}", "update foo: #{foo1_id}", "create foo: #{foo1_id}"],
                 @foo_manager.undoables.collect {|op| op.description}
    assert_equal [], @foo_manager.redoables.collect {|op| op.description}
  end
  
  def test_undo_all_off_and_on_and_off
    Foo.undo_all = false
    Foo.create(:name => 'foo')
    assert_equal false, Foo.undo_all
    assert_equal [], Foo.undo_manager.undoables
    
    Foo.undo_all = true
    new_foo = Foo.create(:name => 'bar')
    assert_equal true, Foo.undo_all
    assert_equal ["create foo: #{new_foo.id}"], Foo.undo_manager.undoables.collect {|op| op.description}
    
    Foo.undo_all = false
    Foo.create(:name => 'foo2')
    assert_equal false, Foo.undo_all
    assert_equal ["create foo: #{new_foo.id}"], Foo.undo_manager.undoables.collect {|op| op.description}
    
    Foo.undo_all = true # set it back to it's default for this class
  end
end

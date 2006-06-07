require File.dirname(__FILE__) + '/test_helper'

class ActsAsUndoableTest < Test::Unit::TestCase
  
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
  
  def test_use_case_foos
    Foo.create(:name => 'foo')
    Foo.find_first.update_attributes(:name => 'MOO')
    foo_change = Foo.undo_manager.last_operation # remeber this point
    Foo.create(:name => 'bar')
    foo_destroy_all = Foo.undoable('destroy all foos') { Foo.destroy_all }
    
    # check there's no foos, and that there's 4 undoables in the right order
    assert_equal [], Foo.find_all
    assert_equal ['destroy all foos', 'create foo: 2', 'update foo: 1', 'create foo: 1'], @foo_manager.undoables.collect {|op| op.description}
    
    # now undo foo_change (undoing all ops in between) and check
    foo_change.undo
    
    assert_equal ['foo'], Foo.find_all.collect {|r| r.name}
    assert_equal ['create foo: 1'], @foo_manager.undoables.collect {|op| op.description}
    assert_equal ['update foo: 1', 'create foo: 2', 'destroy all foos'], @foo_manager.redoables.collect {|op| op.description}
    
    # redo twice (using different idioms) and check
    Foo.undo_manager.redo
    @foo_manager.redo
    assert_equal ['MOO', 'bar'], Foo.find_all.collect {|r| r.name}
    assert_equal ['create foo: 2', 'update foo: 1', 'create foo: 1'], @foo_manager.undoables.collect {|op| op.description}
    assert_equal ['destroy all foos'], @foo_manager.redoables.collect {|op| op.description}
    
    # make new change (this will destory the currently undone foo_destroy_all operation) and check
    Foo.create(:name => 'woooo')
    assert_equal ['MOO', 'bar', 'woooo'], Foo.find_all.collect {|r| r.name}
    assert_equal ['create foo: 3', 'create foo: 2', 'update foo: 1', 'create foo: 1'], @foo_manager.undoables.collect {|op| op.description}
    assert_equal [], @foo_manager.redoables.collect {|op| op.description}
    
    # try and undo the stale foo_destroy_all operation, it will raise an error and do nothing the the db
    assert_raise(Ardes::UndoOperation::Stale) { foo_destroy_all.undo }
    assert_equal ['MOO', 'bar', 'woooo'], Foo.find_all.collect {|r| r.name}    
    assert_equal ['create foo: 3', 'create foo: 2', 'update foo: 1', 'create foo: 1'], @foo_manager.undoables.collect {|op| op.description}
    assert_equal [], @foo_manager.redoables.collect {|op| op.description}
  end
end

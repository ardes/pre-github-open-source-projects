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
    
    create_car_id = @car_manager.execute do |opts| 
      car = Car.new(:name => 'Car')
      (1..4).each {|i| car.car_parts << CarPart.new(:name => "Wheel #{i}")}
      opts[:description] = "Car with 4 wheels created"
      car.save
    end
    create_car = CarUndoOperation.find(create_car_id)
    
    assert_equal [create_car],  @car_manager.undoables
    assert_equal [],            @car_manager.redoables
            
    change_car_id = @car_manager.execute("Lost a wheel and gained a fender") do |opts| 
      wheel = CarPart.find_by_car_id_and_name(car.id, 'Wheel 3')
      wheel.destroy
      car.car_parts << CarPart.new(:name => 'Fender')
      car.name = "Changed Car"
      car.undoable { car.save } # test a nested undoable 
    end
    change_car = CarUndoOperation.find(change_car_id)
    
    assert_equal [change_car, create_car],  @car_manager.undoables
    assert_equal [],                        @car_manager.redoables
    
    # Check the database before undo.  We should have ChangedCar with Wheels 1,2,4 and a Fender
    assert_equal 'Changed Car', Car.find_first.name
    assert_equal ['Wheel 1', 'Wheel 2', 'Wheel 4', 'Fender'], Car.find_first.car_parts.collect {|p| p.name}
    
    # Undo change_car
    @car_manager.undo change_car_id
    
    assert_equal [create_car], @car_manager.undoables
    assert_equal [change_car], @car_manager.redoables
    
    # Check the database to make sure we're back with our car before the change
    assert_equal 'Car', Car.find_first.name
    assert_equal ['Wheel 1', 'Wheel 2', 'Wheel 3', 'Wheel 4'], Car.find_first.car_parts.collect {|p| p.name}
    
    # Undo create_car
    @car_manager.undo create_car_id
    
    assert_equal [],                        @car_manager.undoables
    assert_equal [create_car, change_car],  @car_manager.redoables
    
    # Check the database to make sure we got nothin!
    assert_equal [], Car.find_all
    
    # Redo change_car (which will also redo create_car in order to do this)
    @car_manager.redo change_car_id
    assert_equal [change_car, create_car],  @car_manager.undoables
    assert_equal [],                        @car_manager.redoables
    
    # Check the database before undo.  We should have ChangedCar with Wheels 1,2,4 and a Fender
    assert_equal 'Changed Car', Car.find_first.name
    assert_equal ['Wheel 1', 'Wheel 2', 'Wheel 4', 'Fender'], Car.find_first.car_parts.collect {|p| p.name}
  end
  
  def test_use_case_foos
    Foo.create(:name => 'foo1')
    create_foo1_id = Foo.last_undo_operation_id
    Foo.find_first.update_attributes(:name => 'foo2')
    foo1_becomes_foo2_id = Foo.last_undo_operation_id
    Foo.create(:name => 'foo3')
    create_foo3_id = Foo.last_undo_operation_id
    destroy_all_foo_id = Foo.undoable { Foo.destroy_all } # destory all calls on each obj so we collapse this into one op
    
    # check there's no foos, and that there's 4 undoables in the right order
    assert_equal [], Foo.find_all
    assert_equal [destroy_all_foo_id, create_foo3_id, foo1_becomes_foo2_id, create_foo1_id], @foo_manager.undoables.collect {|op| op.id}
    
    # now undo foo1_becomes_foo2_id (undoaing all ops in between) and check
    @foo_manager.undo foo1_becomes_foo2_id
    
    assert_equal ['foo1'], Foo.find_all.collect {|r| r.name}
    assert_equal [create_foo1_id], @foo_manager.undoables.collect {|op| op.id}
    assert_equal [foo1_becomes_foo2_id, create_foo3_id, destroy_all_foo_id], @foo_manager.redoables.collect {|op| op.id}
  end
end

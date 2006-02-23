require 'load_ar'
require 'test/unit'
require 'ardes/active_record/acts/undo'
require 'acts_as_versioned.rb'

module ArdesTests
  module ActiveRecordActsUndo
        
    class ::Vehicle < ActiveRecord::Base
      acts_as_undoable :vehicles
      has_many :parts, :dependent => true
    end
    
    class ::Part < ActiveRecord::Base
      acts_as_undoable :vehicles
      belongs_to :vehicle
    end

    class ActsAsUndoTest < Test::Unit::TestCase
      
      def setup
        @manager = Ardes::ActiveRecord::Acts::Undo::Manager.for :vehicles
      end
      
      def test_linked
        assert_same @manager, Vehicle.undo_manager
        assert_same @manager, Part.undo_manager
      end
      
      def test_use_case
        car = nil
        
        create_car = @manager.execute do |opts| 
          car = Vehicle.new(:name => 'Car')
          (1..4).each {|i| car.parts << Part.new(:name => "Wheel #{i}")}
          opts[:description] = "Car with 4 wheels created"
          car.save
        end
        
        assert_equal [create_car],  @manager.undoables
        assert_equal [],            @manager.redoables
                
        change_car = @manager.execute(:description => "Lost a wheel and gained a fender") do |opts| 
          wheel = Part.find_by_vehicle_id_and_name(car.id, 'Wheel 3')
          wheel.destroy
          car.parts << Part.new(:name => 'Fender')
          car.name = "Changed Car"
          car.save
        end
        
        assert_equal [change_car, create_car],  @manager.undoables
        assert_equal [],                        @manager.redoables
        
        # Check the database before undo.  We should have ChangedCar with Wheels 1,2,4 and a Fender
        assert_equal 'Changed Car', Vehicle.find_first.name
        assert_equal ['Wheel 1', 'Wheel 2', 'Wheel 4', 'Fender'], Vehicle.find_first.parts.collect {|p| p.name}
        
        # Undo change_car
        @manager.undo change_car
        assert_equal [create_car], @manager.undoables
        assert_equal [change_car], @manager.redoables
        
        # Check the database to make sure we're back with our car before the change
        assert_equal 'Car', Vehicle.find_first.name
        assert_equal ['Wheel 1', 'Wheel 2', 'Wheel 3', 'Wheel 4'], Vehicle.find_first.parts.collect {|p| p.name}
        
        # Undo create_car
        @manager.undo create_car
        assert_equal [],                        @manager.undoables
        assert_equal [create_car, change_car],  @manager.redoables
        
        # Check the database to make sure we got nothin!
        assert_equal [], Vehicle.find_all
        assert_equal [], Part.find_all
        
        # Redo change_car (which will also redo create_car in order to do this)
        @manager.redo change_car
        assert_equal [change_car, create_car],  @manager.undoables
        assert_equal [],                        @manager.redoables
        
        # Check the database before undo.  We should have ChangedCar with Wheels 1,2,4 and a Fender
        assert_equal 'Changed Car', Vehicle.find_first.name
        assert_equal ['Wheel 1', 'Wheel 2', 'Wheel 4', 'Fender'], Vehicle.find_first.parts.collect {|p| p.name}
      end
    end
  end
end
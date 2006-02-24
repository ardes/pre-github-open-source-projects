require 'ardes/undo/versioned/grouping'

module Ardes# :nodoc:
  module ActiveRecord# :nodoc:
    module Acts# :nodoc:
      #
      # Specify this act to enable unodable operations on your ActiveRecord models
      #
      # ===Example of use
      #
      #   class Vehicle < ActiveRecord::Base
      #     acts_as_undoable :vehicles
      #     has_many :parts, :dependent => true
      #   end
      #   
      #   class Part < ActiveRecord::Base
      #     acts_as_undoable :vehicles
      #     belongs_to :vehicle
      #   end
      #   
      #   # get the manager (could also use Vehicle.undo_manager or Part.undo_manager
      #   @manager = Ardes::ActiveRecord::Acts::Undo::Manager.for :vehicles
      #   
      #   # create a car
      #   car = nil
      #   create_car = @manager.execute do |opts| 
      #     car = Vehicle.new(:name => 'Car')
      #     (1..4).each {|i| car.parts << Part.new(:name => "Wheel #{i}")}
      #     opts[:description] = "Car with 4 wheels created"
      #     car.save
      #   end
      #   # => 1 (the id of the undoable corresponding to the above operations)
      #   
      #   # change the car            
      #   change_car = @manager.execute(:description => "Lost a wheel and gained a fender") do |opts| 
      #     wheel = Part.find_by_vehicle_id_and_name(car.id, 'Wheel 3')
      #     wheel.destroy
      #     car.parts << Part.new(:name => 'Fender')
      #     car.name = "Changed Car"
      #     car.save
      #   end 
      #   # => 2
      #   
      #   # what can be undone?
      #   @manager.undoables
      #   # => [2, 1]
      #   
      #   # get a better idea of that (useful for a select list)
      #   @manager.descriptions(@manager.undoables)
      #   # => [[2, "Lost a wheel and gained a fender"], [1, "Car with 4 wheels created"]]
      #   
      #   # Check the database before undo.  We should have ChangedCar with Wheels 1,2,4 and a Fender
      #   Vehicle.find_first.name                       
      #   # => 'Changed Car'
      #   Vehicle.find_first.parts.collect {|p| p.name}
      #   # => ['Wheel 1', 'Wheel 2', 'Wheel 4', 'Fender']
      #   
      #   # Undo change_car (could also use @manager.undo :first, or simply @manager.undo)
      #   @manager.undo change_car
      #   
      #   # Check the database to make sure we're back with our car before the change
      #   Vehicle.find_first.name                       
      #   # => 'Car'
      #   Vehicle.find_first.parts.collect {|p| p.name}
      #   # => ['Wheel 1', 'Wheel 2', 'Wheel 3', 'Wheel 4']
      #   
      #   # Undo create_car
      #   @manager.undo create_car
      #   
      #   # Check that we have nothing in db
      #   Vehicle.find_all                    
      #   # => []
      #   Part.find_all                                 
      #   # => []
      #   
      #   # Redo change_car (which will also redo create_car in order to do this)
      #   @manager.redo change_car
      #   
      #   # Check the database.  We should be back at ChangedCar with Wheels 1,2,4 and a Fender
      #   Vehicle.find_first.name                       
      #   # => 'Changed Car'
      #   Vehicle.find_first.parts.collect {|p| p.name} 
      #   # => ['Wheel 1', 'Wheel 2', 'Wheel 4', 'Fender']
      #   
      module Undo

        def self.included(base)
          base.extend(ClassMethods)
        end

        module ClassMethods
          def acts_as_undoable(*args, &extension)
            # don't allow multiple calls
            return if self.included_modules.include?(Ardes::ActiveRecord::Acts::Undo::ActMethods)
            
            options = args.last.is_a?(Hash) ? args.pop : {}
            scope = (args.pop or :application)
            
            cattr_accessor :undo_manager
            self.undo_manager = Manager.for(scope, *(options[:manager] ? options[:manager] : Array.new) )
            self.undo_manager.manage(self)
            
            acts_as_versioned(options, &extension)
                        
            include ActMethods
          end
        end

        module ActMethods
          
          # Executes the block in an undoable context, using the
          # reciever's undo_manager to execute the block
          def undoable(&block)
            undo_manager.execute(&block)
          end
          
          # send the named method to the reciever in an undoable context, using the
          # reciever's undo_manager to execute the block
          def send_undoable(method_args, *undoable_options)
            if method_args.is_a? Array
              method_name = method_args.shift
             else
              method_name = method_args
              method_args = []
            end
            
            result = nil
            undo_manager.execute(*undoable_options) {result = self.send(method_name, *method_args)}
            result
          end
        end
        
        class Manager < Ardes::Undo::Versioned::Grouping::Manager
        end
      end
    end
  end
end

ActiveRecord::Base.class_eval { include Ardes::ActiveRecord::Acts::Undo }


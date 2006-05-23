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
      #   @manager = Ardes::UndoManager.for :vehicles
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
          #
          # NOTE: acts_as_versioned revert_to! will never create an undo operation, as the
          # versioning callbacks are disbled.  If you need to do this use: obj.revert_to(n); obj.save
          #
          def acts_as_undoable(*args, &extension)
            options = args.last.is_a?(Hash) ? args.pop : {}
            scope = (args.shift or :application)
            undo_all = (args.shift == :all)
            
            cattr_accessor :undo_manager, :last_undo_operation_id, :operation_without_undo
            self.undo_manager = Ardes::UndoManager.register(self, scope)
            
            include ActMethods

            if undo_all
              alias_method_chain :save, :undo
              alias_method_chain :destroy, :undo
            else
              alias_method :save_without_undo, :save
              alias_method :destory_without_undo, :destroy
            end
            
            acts_as_versioned(options, &extension)
          end
        end
        
        module ActMethods
          def self.included(base)
            base.extend ClassMethods
          end
          
          def undoable(attrs = {}, &block)
            self.class.undoable(attrs, &block)
          end

          # send the named method to the reciever in an undoable context, using the
          # reciever's undo_manager to execute the block
          # optionally takes a hash of attributes as the first argument which is
          # passed to the undoable
          def send_undoable(*args)
            undoable_attrs = (args.first.is_a?(Hash) ? args.shift : {})
            result = nil
            self.last_undo_operation_id = undo_manager.execute(undoable_attrs) {result = self.send(*args)}
            result
          end
          
          # Executes the block with undo disabled.
          # This method is only useful if you have set :undo_all
          #
          #   @foo.without_undo { @foo.save }
          #
          def without_undo(&block)
            undo_manager.without_undo(&block)
          end
          
          def save_with_undo(*args)
            return save_without_undo(*args) if undo_manager.no_undo
            result = nil
            self.last_undo_operation_id = undo_manager.execute { result = save_without_undo(*args) }
            result
          end
      
          def destroy_with_undo(*args)
            return destroy_without_undo(*args) if undo_manager.no_undo
            result = nil
            self.last_undo_operation_id = undo_manager.execute { result = destroy_without_undo(*args) }
            result
          end

          module ClassMethods
            # Executes the block in an undoable context, using the
            # reciever's undo_manager to execute the block
            # All nested undoables are coalesced into the top level undoable
            def undoable(attrs = {}, &block)
              self.last_undo_operation_id = self.undo_manager.execute(attrs, &block)
            end
            
            # Executes the block with undo disabled.
            # This method is only useful if you have set :undo_all
            #
            #   Foo.without_undo do
            #     @foo.save
            #   end
            #
            def without_undo(&block)
              undo_manager.without_undo(&block)
            end
          end
        end
      end
    end
  end
end

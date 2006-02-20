require 'ardes/active_record/undo/versioned'

module Ardes
  module ActiveRecord
    module Acts
      #
      # m.undoable do
      #   Window.create()...
      # end
      #
      module Undo

        def self.included(base)
          base.extend(ClassMethods)
        end

        module ClassMethods
          def acts_as_undoable(*args, &extension)
            options = args.last.is_a?(Hash) ? args.pop : {}
            scope = (args.pop or :application)
            
            cattr_accessor :undo_manager
            self.undo_manager = Ardes::ActiveRecord::Undo::Versioned::Manager.for(scope, options[:undo_stack])
            
            before_save     self.undo_manager
            before_destroy  self.undo_manager
            after_save      self.undo_manager
            after_destroy   self.undo_manager
            
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
          
          def send_undoable(methodname, *args)
            undo_manager.execute {self.send(methodname, *args)}
          end
        end
      end
    end
  end
end

ActiveRecord::Base.class_eval { include Ardes::ActiveRecord::Acts::Undo }


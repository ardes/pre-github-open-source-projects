module Ardes# :nodoc:
  module ActionController# :nodoc:
    module Acts# :nodoc:
      module Undo

        def self.included(base)
          base.extend(ClassMethods)
        end

        module ClassMethods
          def setup_common(scope)
            unless self.included_modules.include?(Ardes::ActionController::Acts::Undo::InstanceMethods)
              include InstanceMethods
              cattr_accessor :undo_scope
              self.undo_scope = scope
              helper :undo
              before_filter :load_undo_manager
            end
          end
          
          def acts_as_undo_manager(scope)
            setup_common(scope)
            include ManagerMethods
          end

          def acts_as_undoable(scope, *conditions)
            setup_common(scope)
            include UndoableMethods
            before_filter(:start_undoable, *conditions)
            after_filter(:end_undoable, *conditions)
          end

        end
        
        module InstanceMethods
        private 
          def load_undo_manager
            @undo_scope = self.undo_scope
            @undo_manager = Ardes::ActiveRecord::Acts::Undo::Manager.for @undo_scope
          end
        end
        
        module ManagerMethods
          def undo
            @undo_manager.undo(params[:id].nil? ? :first : params[:id])
            redirect_to_return params[:return_to]
           end
  
          def redo
            @undo_manager.redo(params[:id].nil? ? :first : params[:id])
            redirect_to_return params[:return_to]
          end
        
        private
          def redirect_to_return(params)
            params = YAML.load(params)
            controller = params.delete :controller
            action = params.delete :action
            redirect_to :controller => controller, :action => action, :params => params
          end
            
        end
        
        module UndoableMethods
        private
          def start_undoable
            @undo_manager.start_undoable
          end
          
          def end_undoable
            @undo_manager.end_undoable
          end
        end
      end
    end
  end
end

ActionController::Base.class_eval { include Ardes::ActionController::Acts::Undo }


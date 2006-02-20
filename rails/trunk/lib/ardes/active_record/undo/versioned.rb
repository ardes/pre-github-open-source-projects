require 'ardes/active_record/undo'

module Ardes
  module ActiveRecord
    module Undo
      module Versioned
        def self.included(base) # :nodoc:
            base.extend ClassMethods
        end
        
        module ClassMethods
          def acts_as_versioned_undo_stack
            acts_as_undo_stack
            class_eval { extend SingletonMethods }
            include InstanceMethods
          end
        end
        
        module SingletonMethods
          def create_undo_table(create_table_options = {})
            self.connection.create_table(table_name, create_table_options) do |t|
              t.column :undone, :boolean, :default => false, :null => false
              t.column :obj_class_name, :string, :null => false
              t.column :obj_id, :integer, :null => false
              t.column :down_version, :integer, :null => true
              t.column :up_version, :integer, :null => true
              t.column :obj_description, :string, :null => true
            end
          end

          # Rake migration task to drop the command stack table
          def drop_undo_table
            self.connection.drop_table table_name
          end
        end
        
        module InstanceMethods        
         protected
         
          def on_undo
            change_version(self.up_version, self.down_version)
          end

          def on_redo
            change_version(self.down_version, self.up_version)
          end

          def change_version(from_version, to_version)
            return true if from_version == to_version

            # guard against rogue databse data
            unless eval("defined?(#{obj_class_name})") == 'constant'
              raise RuntimeError, "Invalid Class: #{self.obj_class_name.inspect}"
            end
          
            obj_class = eval obj_class_name

            if to_version.nil?
              obj_class.destroy self.obj_id
            else
              # There's probably a better way to do this
              # This way: create a new obj, set it's pk and revert the object
              # If we're not creating, set @new_record = false to stop INSERT
              obj = obj_class.new
              obj.instance_eval "@attributes[self.class.primary_key] = #{self.obj_id}"
              obj.instance_eval "@new_record = false" unless from_version.nil?
              obj.revert_to! to_version
            end
          end
        end
        
        class Manager < Ardes::Undo::Manager

          @@managers = Hash.new

          def self.for(scope = :application, stack = nil)
            scope = scope.to_s.singularize
            
            # Return the manager for the scope if we have one
            return @@managers[scope] if @@managers[scope]
            
            # If passed an undo stack, use that for the new manager
            return @@managers[scope] = self.new(stack) if stack
            
            # Otherwise infer the stack class name from the scope
            stack_class_name = scope.classify << "UndoItem"

            # Create the command stack ActiveRecord class if it doesn't exist
            unless self.const_defined? stack_class_name
              eval <<-EOL
                 class ::#{stack_class_name} < ::ActiveRecord::Base
                   acts_as_versioned_undo_stack
                 end
              EOL
            end
            
            # Create the new manager with the inferred class name
            eval "@@managers[scope] = self.new #{stack_class_name}"
          end

          def execute(&block)
            if @stack.respond_to? :transaction
              @stack.transaction { execute_block(&block) }
            else
              execute_block(&block)
            end
          end
          
          alias_method :undoable, :execute
          
          def before_save(r)
            return unless @capturing
            @down[r.object_id] = r.version
          end

          alias_method :before_destroy, :before_save

          def after_save(r)
            return unless @capturing
            capture_item(r, r.version)
          end

          def after_destroy(r)
            return unless @capturing
            capture_item(r, nil)
          end
          
        protected
          def execute_block
            start_undoable
            yield
          ensure
            end_undoable
          end

          def start_undoable
            @down = Hash.new
            @items = Array.new
            @capturing = true
          end
         
          def end_undoable
            @capturing = false
            if @items.size > 0
              @stack.delete_undone_items
              @items.collect {|item| [@stack.push_item(item), item]}
            end
            @items
          end

          def capture_item(r, up_version)
            unless @down[r.object_id] == up_version
              if (desc = r.to_s) =~ /^\#\<.*\>$/  #don't use to_s if it's the default Object.to_s
                desc = "#{r.class.name.downcase}: #{r.attributes[r.class.primary_key]}"
              end
              @items << @stack.new(
                :obj_class_name   => r.class.name,
                :obj_id           => r.attributes[r.class.primary_key],
                :down_version     => @down[r.object_id],
                :up_version       => up_version,
                :obj_description  => desc)
            end
            @down.delete r.object_id
            true
          end
        end
      end
    end
  end
end

ActiveRecord::Base.class_eval { include Ardes::ActiveRecord::Undo::Versioned }
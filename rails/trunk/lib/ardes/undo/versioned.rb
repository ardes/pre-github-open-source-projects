require 'ardes/undo/active_record_stack'

module Ardes# :nodoc:
  module Undo# :nodoc:
    module Versioned# :nodoc:
      class Manager < Ardes::Undo::Manager

        attr_reader :managed

        @@managers = Hash.new

        def self.for(scope = :application, *args)
          scope = scope.to_s.singularize
          # Return the manager for the scope if we have one
          if @@managers[scope]  
            return @@managers[scope] 
          # If passed args, use them to make new manager
          elsif args.size > 0   
            return @@managers[scope] = self.new(*args)
          # Otherwise, create the new manager with stack from scope
          else                 
            return @@managers[scope] = self.new(active_record_stack_for_scope(scope))
          end
        end
        
        def self.active_record_stack_for_scope(scope)
          stack_class_name = scope.classify << "UndoItem"

          # Create the command stack ActiveRecord class if it doesn't exist
          unless eval("defined?(#{stack_class_name})") == 'constant'
            eval <<-EOL
               class ::#{stack_class_name} < ::ActiveRecord::Base
                 include Ardes::Undo::Versioned::ActiveRecordStack
               end
            EOL
          end
          eval stack_class_name
        end

        def initialize(*args)
          super(*args)
          @managed = Array.new
        end
        
        # this call must be made before acts_as_versioned is called
        # otherwise the callbacks will not occur in the correct order to capture versioning info
        def manage(acting_as_undoable)
          unless @managed.include? acting_as_undoable
            undo_manager = self
            acting_as_undoable.class_eval do
              before_save     undo_manager
              before_destroy  undo_manager
              after_save      undo_manager
              after_destroy   undo_manager
             end
            @managed << acting_as_undoable 
          end
        end
        
        # Rake migration task to create all tables needed by acts_as_undoable
        # Before using this method, ensure that all classes that act_as_undoable are loaded
        def create_tables(create_table_options = {})
          @managed.each {|m| m.create_versioned_table(create_table_options) }
          @stack.create_table(create_table_options)
        end
        
        # Rake migration task to drop all acts_as_undoable tables
        # Before using this method, ensure that all classes that act_as_undoable are loaded
        def drop_tables
          @stack.drop_table
          @managed.each {|m| m.drop_versioned_table }
        end
                  
        def execute(*args, &block)
          if @stack.respond_to? :transaction
            @stack.transaction { execute_block(*args, &block) }
          else
            execute_block(*args, &block)
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
          capture_undoable(r, @down[r.object_id], r.version)
          @down.delete r.object_id
        end

        def after_destroy(r)
          return unless @capturing
          capture_undoable(r, @down[r.object_id], nil)
          @down.delete r.object_id
         end
        
      protected
        def capture_undoable(record, down_version, up_version)
          @undoables << @stack.new(
              :obj_class_name   => record.class.name,
              :obj_id           => record.attributes[record.class.primary_key],
              :down_version     => down_version,
              :up_version       => up_version)
        end
        
        def execute_block(*args)
          start_undoable
          yield(*args)
          end_undoable(*args)
        end

        def start_undoable
          @down = Hash.new
          @undoables = Array.new
          @capturing = true
        end
       
        def end_undoable(*args)
          @capturing = false
          if @undoables.size > 0
            @stack.delete_undone_items
            push_undoables(*args)
          else
            Array.new
          end
        end
        
        def push_undoables(*args)
          @undoables.collect {|undoable| @stack.push_item(undoable, *args)}
        end
      end
      
      module ActiveRecordStack
        def self.included(base) # :nodoc:
          super
          base.class_eval do
            include Ardes::Undo::ActiveRecordStack
            extend SingletonMethods
            include InstanceMethods
          end
        end

        module SingletonMethods
          def create_table(create_table_options = {})
            self.connection.create_table(table_name, create_table_options) do |t|
              t.column :undone, :boolean, :default => false, :null => false
              t.column :obj_class_name, :string, :null => false
              t.column :obj_id, :integer, :null => false
              t.column :down_version, :integer, :null => true
              t.column :up_version, :integer, :null => true
              t.column :created_at, :timestamp
            end
          end

          # Rake migration task to drop the command stack table
          def drop_table
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
      end
    end
  end
end
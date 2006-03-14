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
            return @@managers[scope] = self.new(stack_for_scope(scope))
          end
        end
        
        def self.stack_for_scope(scope)
          stack_class_name = scope.classify << "UndoItem"
          stack_class_name.constantize
          
        rescue NameError # create stack on demand
          create_stack_class(stack_class_name)
        end
        
        def self.create_stack_class(stack_class_name)
          eval <<-EOL
             class ::#{stack_class_name} < ::ActiveRecord::Base
               include Ardes::Undo::Versioned::ActiveRecordStack
               def self.reloadable? ; false ; end
             end
          EOL
          stack_class_name.constantize
        end

        def initialize(stack)
          super(stack)
          @managed = Hash.new
        end
        
        # this call must be made before acts_as_versioned is called
        # otherwise the callbacks will not occur in the correct order to capture versioning info
        def manage(acting_as_undoable)
          acting_as_undoable.before_save self
          acting_as_undoable.before_destroy self
          acting_as_undoable.after_save self
          acting_as_undoable.after_destroy self
          
          @managed[acting_as_undoable.name] = acting_as_undoable
        end
        
        # Rake migration task to create all tables needed by acts_as_undoable
        # Before using this method, ensure that all classes that act_as_undoable are loaded
        def create_tables(create_table_options = {}, create_versioned_tables = false)
          if create_versioned_tables 
            @managed.each {|name, m| m.create_versioned_table(create_table_options) }
          end
          @stack.create_table(create_table_options)
        end
        
        # Rake migration task to drop all acts_as_undoable tables
        # Before using this method, ensure that all classes that act_as_undoable are loaded
        def drop_tables(drop_versioned_tables = false)
          @stack.drop_table
          if drop_versioned_tables
            @managed.each {|name, m| m.drop_versioned_table }
          end
        end
                  
        def execute(*args, &block)
          if @stack.respond_to? :transaction
            @stack.transaction { execute_block(*args, &block) }
          else
            execute_block(*args, &block)
          end
        end
        
        def description(id)
          @stack.item_at(id).description
        end
        
        def descriptions
          descs = Hash.new
          @stack.items {|r| descs[r.id] = r.description}
          descs
        end
        
        def descriptions_for(ids = nil)
          descs = descriptions
          ids.collect {|id| [descs[id], id]}
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
        
       def start_undoable
         unless @capturing
           @down = Hash.new
           @undoables = Array.new
           @capturing = true
         end
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

      protected
        def capture_undoable(record, down_version, up_version)
          return if down_version == up_version
          @undoables << @stack.new(
              :obj_class_name   => record.class.name,
              :obj_id           => record.attributes[record.class.primary_key],
              :down_version     => down_version,
              :up_version       => up_version,
              :obj_description  => record.respond_to?(:short_description) ? record.short_description : nil)
        end
        
        def execute_block(*args)
          start_undoable
          yield(*args)
          end_undoable(*args)
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
              t.column :obj_description, :string
              t.column :created_at, :timestamp
            end
          end

          # Rake migration task to drop the command stack table
          def drop_table
            self.connection.drop_table table_name
          end
        end

        module InstanceMethods       
          def description
            return attributes['description'] if attributes['description']
            desc = (down_version.nil? ? 'create' : (up_version.nil? ? 'destroy' : 'update')) + ' '
            desc += (obj_description or (obj_class_name.humanize.downcase + ': ' + obj_id.to_s))
          end 
         
         protected

          def on_undo
            change_version(self.up_version, self.down_version)
          end

          def on_redo
            change_version(self.down_version, self.up_version)
          end

          def change_version(from_version, to_version)
            return true if from_version == to_version

            obj_class = obj_class_name.constantize

            if to_version.nil?
              # sometimes ActiveRecord saves record in an order that means that dependent
              # objects will be destroyed by dependent associations before we get the
              # chance to destroy them, hence 'rescue ::ActiveRecord::RecordNotFound'
              obj_class.destroy self.obj_id rescue ::ActiveRecord::RecordNotFound
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
require 'ardes/undo/versioned'

module Ardes# :nodoc:
  module Undo# :nodoc:
    module Versioned# :nodoc:
      module Grouping
        class Manager < Ardes::Undo::Versioned::Manager
        
          def self.active_record_stack_for_scope(scope)
            stack_class_name = scope.classify << "UndoItem"

            unless eval("defined?(#{stack_class_name})") == 'constant'
              eval <<-EOL
                 class ::#{stack_class_name} < ::ActiveRecord::Base
                   include Ardes::Undo::Versioned::Grouping::ActiveRecordStack
                 end
              EOL
            end
            eval stack_class_name
          end
          
          # Rake migration task to create all tables needed by acts_as_undoable
          # Before using this method, ensure that all classes that act_as_undoable are loaded
          def create_tables(create_table_options = {})
            super(create_table_options)
            @stack.atoms.create_table(create_table_options)
          end

          # Rake migration task to drop all acts_as_undoable tables
          # Before using this method, ensure that all classes that act_as_undoable are loaded
          def drop_tables
            @stack.atoms.drop_table
            super
          end
          
        protected
          def capture_undoable(record, down_version, up_version)
            @undoables << @stack.atoms.new(
                :obj_class_name   => record.class.name,
                :obj_id           => record.attributes[record.class.primary_key],
                :down_version     => down_version,
                :up_version       => up_version)
          end
        
          def push_undoables
            @stack.push_item(@stack.new_item(@undoables,''))
          end
        end
      
        module ActiveRecordStack
          def self.included(base) # :nodoc:
            super
            base.class_eval do
              include Ardes::Undo::ActiveRecordStack
              
              # create atom class
              atom_class_name = self.name + 'Atom'
              eval <<-EOL
                class ::#{atom_class_name} < ::ActiveRecord::Base
                  include ActiveRecordAtom
                  cattr_accessor :stack
                  self.stack = #{self.name}
                  belongs_to :#{table_name.singularize}
                end
              EOL
              
              cattr_accessor :atoms
              self.atoms = atom_class_name.constantize
              
              has_many atom_class_name.tableize.to_sym, :dependent => true
              
              extend SingletonMethods
              include InstanceMethods
            end
          end

          module SingletonMethods

            def new_item(atoms, description)
              item = self.new
              item.send("#{self.atoms.table_name}=", atoms)
              item.description = description
              item
            end
            
            # this call must be made before acts_as_versioned is called
            # otherwise the callbacks will not occur in the correct order to capture versioning info
            def create_table(create_table_options = {})
              self.connection.create_table(table_name, create_table_options) do |t|
                t.column :undone, :boolean, :default => false, :null => false
                t.column :description, :string
                t.column :created_at, :timestamp
              end
            end

            # Rake migration task to drop all acts_as_undoable tables
            # Before using this method, ensure that all classes that act_as_undoable are loaded
            def drop_table
              self.connection.drop_table table_name
            end
          end

          module InstanceMethods
            
          protected
            def on_undo
              send(self.atoms.table_name).reverse_each {|atom| atom.on_undo}
            end

            def on_redo
              send(self.atoms.table_name).each {|atom| atom.on_redo}
            end
          end
        end
        
        module ActiveRecordAtom
          def self.included(base) # :nodoc:
            super
            base.class_eval do
              extend SingletonMethods
              include InstanceMethods
            end
          end
          
          module SingletonMethods
            def create_table(create_table_options = {})
              self.connection.create_table(table_name, create_table_options) do |t|
                t.column self.stack.name.foreign_key, :integer
                t.column :obj_class_name, :string, :null => false
                t.column :obj_id, :integer, :null => false
                t.column :down_version, :integer, :null => true
                t.column :up_version, :integer, :null => true
              end
            end
          
            # Rake migration task to drop the group table
            def drop_table
              self.connection.drop_table table_name
            end
          end
          
          module InstanceMethods
            include Ardes::Undo::Versioned::ActiveRecordStack::InstanceMethods
            
          public
            def on_undo; super; end
            def on_redo; super; end
          end
        end
      end
    end
  end
end
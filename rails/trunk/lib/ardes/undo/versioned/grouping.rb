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
          end
        end
        
        module ActiveRecordStack
          def self.included(base) # :nodoc:
            super
            base.class_eval do
              atom_class_name = self.name + 'Atom'
              # create atom class
              eval <<-EOL
                class ::#{atom_class_name} < ::ActiveRecord::Base
                  include ActiveRecordAtom
                  belongs_to :#{table_name}
                end
              EOL
              cattr_accessor :atom_class, :atom_table_name
              self.atom_class      = eval atom_class_name
              self.atom_table_name = atom_class_name.tableize
              
              has_many self.atom_table_name.to_sym, :dependent => true
              extend SingletonMethods
              include InstanceMethods
            end
          end

          module SingletonMethods
            include Ardes::Undo::ActiveRecordStack::SingletonMethods

            def new_item(items)
            end
            
            def create_table(create_table_options = {})
              self.connection.create_table(table_name, create_table_options) do |t|
                t.column :undone, :boolean, :default => false, :null => false
                t.column :description, :string
                t.column :created_at, :timestamp
              end
            end

            # Rake migration task to drop the group table
            def drop_table
              self.connection.drop_table table_name
            end
          end

          module InstanceMethods
            include Ardes::Undo::ActiveRecordStack::InstanceMethods
            
          protected
            def on_undo
              send(self.atom_table_name).each {|a| a.on_undo}
            end

            def on_redo
              send(self.atom_table_name).reverse_each {|a| a.on_redo}
            end
          end
        end
      end
    end
  end
end
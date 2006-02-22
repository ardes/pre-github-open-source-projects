require 'ardes/undo/versioned'

module Ardes# :nodoc:
  module Undo# :nodoc:
    module Versioned# :nodoc:
      module Grouping
        class Manager < Ardes::Undo::Versioned::Manager
          attr_reader :grouping
        
          def self.for(scope = :application, *args)
            manager = super(scope, *args)
          
            unless manager.grouping
              grouping_class_name = scope.to_s.singularize.classify + 'UndoGrouping'
              unless eval("defined?(#{grouping_class_name})") == 'constant'
                eval <<-EOL
                  class ::#{grouping_class_name} < ::ActiveRecord::Base
                    include Ardes::Undo::Versioned::Grouping::ActiveRecord
                    undo_table_name = '#{manager.stack.table_name}'
                  end
                EOL
              end
              manager.instance_eval { @grouping = eval grouping_class_name }
            end
            manager
          end

          def initialize(stack, grouping = nil)
            super(stack)
            @grouping = grouping
          end
        end
      
        module ActiveRecord
          def self.included(base) # :nodoc:
            super
            base.class_eval do
              extend SingletonMethods
              include InstanceMethods
              cattr_accessor :undo_table_name
              self.undo_table_name = self.name.gsub('Grouping', 'Item').tableize
            end
          end

          module SingletonMethods
            def create_table(create_table_options = {})
              self.connection.create_table(table_name, create_table_options) do |t|
                 t.column :description, :string
              end
              self.connection.add_column self.undo_table_name, :grouping_id, :integer
            end

            # Rake migration task to drop the group table
            def drop_table
              self.connection.drop_table table_name
              self.connection.remove_column self.undo_table_name, :grouping_id
            end
          end

          module InstanceMethods
          end
        end
      end
    end
  end
end
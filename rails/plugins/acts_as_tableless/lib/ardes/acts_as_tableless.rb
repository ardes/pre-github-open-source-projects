module Ardes# :nodoc:
  module ActiveRecord# :nodoc:
    module Acts# :nodoc
      module Tableless
        def self.included(base)
          base.extend(ClassMethods)
        end
      
        module ClassMethods
          #
          # Specify that this active record works without a table in the db
          # Specifying columns uses the same syntax as for migrations
          # 
          # usage:
          #   acts_as_tableless :my_col, :my_other_col
          #
          #   acts_as_tableless do
          #     column :my_col, :integer, :null => false
          #     column :my_other_col, :string, :default => 'hello!', :null => true
          #   end
          def acts_as_tableless(*columns)
            include ActMethods
            columns.each {|c| column(c)}
            yield if block_given?
          end
        end
      
        module ActMethods
          def self.included(base)
            base.class_eval do
              extend ClassMethods
              alias_method :save, :valid?
            end
          end

          module ClassMethods
            def columns
              @columns ||= []
            end
          
            def column(name, type = nil, options = {})
              columns << Column.new(name.to_s, type, options)
            end
          end
        end
      
        class Column < ::ActiveRecord::ConnectionAdapters::Column
          def initialize(name, type = nil, options = {})
            @name    = name
            @type    = type
            @null    = options[:null]
            @default = type_cast(options[:default])
            @limit   = options[:limit]
            @primary = nil
            @text    = [:string, :text].include? @type
            @number  = [:float, :integer].include? @type
          end
        end
      end
    end
  end
end

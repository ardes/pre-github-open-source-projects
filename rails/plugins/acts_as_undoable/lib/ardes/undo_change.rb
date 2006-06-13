module Ardes
  module UndoChange
    
    class ChangeFailed < RuntimeError; end
    
    def self.class_for(operation_class)
      class_name = operation_class.name.sub(/Operation$/, 'Change')
      class_name.constantize
    rescue NameError # create class on demand
      eval <<-eval_end
        class ::#{class_name} < ::ActiveRecord::Base
          include ::Ardes::UndoChange
          belongs_to :operation, :class_name => '#{operation_class.name}', :foreign_key => 'operation_id'
          def self.reloadable? ; false ; end
        end
      eval_end
      class_name.constantize
    end
    
    def self.included(base) # :nodoc:
      base.class_eval do
        extend ClassMethods
      end
    end

    module ClassMethods
      # Rake migration task to create the change table
      def create_table(create_table_options = {})
        self.connection.create_table(table_name, create_table_options) do |t|
          t.column :operation_id, :integer, :null => false
          t.column :obj_class_name, :string, :null => false
          t.column :obj_id, :integer, :null => false
          t.column :obj_desc, :string
          t.column :down_version, :integer, :null => true
          t.column :up_version, :integer, :null => true
        end
      end

      # Rake migration task to drop the change table
      def drop_table
        self.connection.drop_table table_name
      end
    end

    def change_desc
      (@attributes['up_version'].nil? ? "destroy" : (@attributes['down_version'].nil? ? "create" : "update")) + " " + self.obj_desc
    end
    
    def obj_desc
      @attributes['obj_desc'] || "#{@attributes['obj_class_name'].underscore.sub('_',' ')}: #{@attributes['obj_id']}"
    end

    def undo
      change_version(@attributes['up_version'], @attributes['down_version']) or raise ChangeFailed, "Change #{obj_desc} from: #{up_version or 'nil'} to: #{down_version or 'nil'} failed" 
    end
  
    def redo
      change_version(@attributes['down_version'], @attributes['up_version']) or raise ChangeFailed, "Change #{obj_desc} from: #{down_version or 'nil'} to: #{up_version or 'nil'} failed" 
    end

  protected
    def change_version(from_version, to_version)
      return true if from_version == to_version

      obj_class = @attributes['obj_class_name'].constantize

      obj_class.without_undo do
        if to_version.nil?
          obj_class.delete(@attributes['obj_id'])
        else
          if from_version.nil? or !(obj = obj_class.find(@attributes['obj_id']) rescue nil)
            obj = obj_class.new
            obj.instance_eval "@attributes[self.class.primary_key] = #{@attributes['obj_id']}"
          end
          obj.revert_to(to_version)
          obj.without_revision { obj.save(false) }
        end
      end
    end
  end
end
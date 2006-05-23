module Ardes
  module UndoChange
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
      (self.up_version.nil? ? "destroy" : (self.down_version.nil? ? "create" : "update")) + " " + self.obj_desc
    end
    
    def obj_desc
      self.attributes['obj_desc'] || "#{self.obj_class_name.underscore.sub('_',' ')}: #{self.obj_id}"
    end

    def undo
      change_version(self.up_version, self.down_version) or raise "Undo failed"
    end
  
    def redo
      change_version(self.down_version, self.up_version) or raise "Redo failed"
    end

  protected
    def change_version(from_version, to_version)
      return true if from_version == to_version

      obj_class = obj_class_name.constantize

      obj_class.without_undo do
        if to_version.nil?
          # TODO: should this be delete?
          obj_class.find(self.obj_id).destroy
        else
          # There's probably a better way to do this
          # This way: create a new obj, set it's pk and revert the object
          # If we're not creating, set @new_record = false to stop INSERT
          obj = obj_class.new
          obj.instance_eval "@attributes[self.class.primary_key] = #{self.obj_id}"
          obj.instance_eval "@new_record = false" unless from_version.nil?
          obj.revert_to!(to_version)
        end
      end
    end
  end
end
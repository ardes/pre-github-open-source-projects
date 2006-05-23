require 'ardes/undo_change'

module Ardes
  module UndoOperation
    
    # Error raised when undo() is called on an item that is already undone
    class Undone < RuntimeError; end
    
    # Error raised when redo() is called on an item that has not been undone
    class NotUndone < RuntimeError; end
    
    def self.class_for(scope)
      class_name = scope.to_s.classify + 'UndoOperation'
      class_name.constantize
    rescue NameError # create class on demand
      eval <<-eval_end
        class ::#{class_name} < ::ActiveRecord::Base
          include ::Ardes::UndoOperation
          def self.reloadable? ; false ; end
        end
      eval_end
      class_name.constantize
    end

    def self.included(base)
      base.class_eval do
        cattr_accessor :change_class
        self.change_class = Ardes::UndoChange.class_for(self)
        has_many :changes, :dependent => true, 
          :class_name  => self.change_class.name,
          :foreign_key => 'operation_id',
          :order       => "#{self.change_class.table_name}.id"
        extend ClassMethods
      end
    end
    
    module ClassMethods
      def new_change(*args)
        self.change_class.new(*args)
      end
      
      # Rake migration task to create the change table
      def create_table(create_table_options = {})
        self.connection.create_table(table_name, create_table_options) do |t|
          t.column :undone, :boolean, :default => false, :null => false
          t.column :description, :string
          t.column :updated_at, :timestamp
        end
      end

      # Rake migration task to drop all acts_as_undoable tables
      def drop_table
        self.connection.drop_table table_name
      end
      
      def push(changes, attrs = {})
        self.find(:all, :conditions => ['undone = ?', true]).each {|op| op.destroy}
        op = self.new(attrs)
        op.changes = changes
        op.save
        op.id
      end
    end
    
    def undo
      changes.each { |change| change.undo }
      self.undone = true
      save!
    end
    
    def redo
      changes.each { |change| change.redo }
      self.undone = false
      save!
    end
  end
end
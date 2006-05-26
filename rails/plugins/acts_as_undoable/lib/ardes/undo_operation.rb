require 'ardes/undo_change'

module Ardes
  module UndoOperation
    
    # Error raised when undo is called on an item that is already undone
    class Undone < RuntimeError; end
    
    # Error raised when redo is called on an item that has not been undone
    class NotUndone < RuntimeError; end
    
    # Error raised when undo or redo is called on a stale operation
    class Stale < RuntimeError; end
    
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
        class <<self
          alias_method_chain :find, :undo_operation
        end
      end
    end
    
    module ClassMethods
      # accepts extra first argument (:undone, :not_undone) to find undoables and redoables
      # examples
      # find :undone        (defaults to all)
      # find :undone, :all
      # find :not_undone, :first
      # find :not_undone, :last
      # find :undone, :to => 6
      def find_with_undo_operation(*args)
        return find_without_undo_operation(*args) unless args.first == :undone || args.first == :not_undone
        
        descending = undone = args.shift == :undone
        options = args.last.is_a?(Hash) ? args.pop : {}
        to = options.delete(:to) rescue nil
        how_many = args.size == 0 ? :all : args.shift
        if how_many == :last
          descending = !descending
          how_many = :first
        end
        
        unless args.size == 0 and (how_many == :all or how_many == :first)
          raise ArgumentError, 'second argument should be :all, :first, :last, :to => some_id or non-existent'
        end
        
        with_scope(:find => {:conditions => ['undone = ?', undone]}) do
          options[:conditions] = ["#{self.table_name}.id #{descending ? '<=' : '>='} ?", to] if to
          options[:order] = "#{self.table_name}.id#{descending ? '' : ' DESC'}"
          find_without_undo_operation(how_many, options)
        end
      end
      
      def new_change(*args)
        self.change_class.new(*args)
      end
      
      def push(changes, attrs = {})
        self.find(:all, :conditions => ['undone = ?', true]).each {|op| op.destroy}
        op = self.new(attrs)
        op.changes = changes
        op.save!
        op
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
    end
    
    # undoes the current operation (and any up to that point)
    def undo
      transaction do
        undoables = self.class.find(:not_undone, :all, :to => self.id, :include => :changes)
        raise Stale unless undoables.include? self
        undoables.each do |op|
          op.changes.each { |change| change.undo }
          op.undone = true
          op.save!
        end
      end
    end
    
    # redoes the current operation (and any up to that point)
    def redo
      transaction do
        redoables = self.class.find(:undone, :all, :to => self.id, :include => :changes)
        raise Stale unless redoables.include? self
        redoables.each do |op|
          op.changes.each { |change| change.redo }
          op.undone = false
          op.save!
        end
      end
    end
  end
end
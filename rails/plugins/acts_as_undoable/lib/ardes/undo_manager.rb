require 'ardes/undo_operation'

module Ardes
  class UndoManager
    @@managers = {}
    attr_reader :no_undo
    
    # manager must be registered before the call to acts_as_versioned, to get
    # callbacks working properly, this is handled in acts_as_undoable.
    def self.register(acting_as_undoable, scope = :application)
      self.for(scope).manage(acting_as_undoable)
    end
  
    def self.for(scope = :application)
      scope = scope.to_s.tableize.singularize
      @@managers[scope] ||= self.new(Ardes::UndoOperation.class_for(scope))
    end
    
    def create_undo_tables(create_table_options = {})
      @operations.create_table(create_table_options)
      @operations.change_class.create_table(create_table_options)
    end
    
    def drop_undo_table()
      @operations.drop_table
      @operations.change_class.drop_table
    end

    def manage(acting_as_undoable)
      acting_as_undoable.before_save self
      acting_as_undoable.before_destroy self
      acting_as_undoable.after_save self
      acting_as_undoable.after_destroy self
      self
    end
    
    # ActiveRecord callbacks
    def before_save(record)
      return if @depth == 0 or @no_undo
      @before_change_version[record.object_id] = record.version
    end

    alias_method :before_destroy, :before_save

    def after_save(record)
      return if @depth == 0 or @no_undo
      capture_change(record, @before_change_version[record.object_id], record.version)
      @before_change_version.delete record.object_id
    end

    def after_destroy(record)
      return if @depth == 0 or @no_undo
      capture_change(record, @before_change_version[record.object_id], nil)
      @before_change_version.delete record.object_id
    end
    # end ActiveRecord callbakcs

    def initialize(operations)
      @operations = operations
      reset_execute
    end

    def undo(to = :first)
      @operations.transaction {find_operations(false, to, :include => :changes).each {|op| op.undo}}
    end

    def redo(to = :first)
      @operations.transaction {find_operations(true, to, :include => :changes).each {|op| op.redo}}
    end

    # to may be :first, an id, or :all (default)
    def undoables(to = :all)
      find_operations(false, to)
    end

    # to may be :first, an id, or :all (default)
    def redoables(to = :all)
      find_operations(true, to)
    end

    # handles nested calls by collapsing all changes into the top level
    # execution context.
    # If an error is raised the undoable is abandoned
    def execute(attrs = {})
      attrs = {:description => attrs} if attrs.is_a? String
      if (@depth += 1) == 1
        @operations.transaction { yield(attrs) }
      else
        yield(attrs)
      end
    rescue
      @no_undo = true
      raise
    else
      push_changes(attrs) if @depth == 1 unless @no_undo
    ensure
      reset_execute if (@depth -= 1) == 0
    end

    alias_method :undoable, :execute

    def without_undo(&block)
      @no_undo = true
      result = block.call
      @no_undo = false
      result
    end
    
  protected
    def reset_execute
      @depth = 0
      @before_change_version = Hash.new
      @changes = Array.new
      @no_undo = false
    end
    
    def find_operations(undone, to, find_options = {})
      cond = "undone = :undone"
      cond_vars  = {:undone => undone}
      if to == :first or to == :all
        how_many = to
      else
        how_many = :all
        cond += " AND #{@operations.table_name}.id #{undone ? '<=' : '>='} :to"
        cond_vars[:to] = to
      end
      find_options[:order] = "#{@operations.table_name}.id#{undone ? '' : ' DESC'}"
      find_options[:conditions] = [cond, cond_vars]
      result = @operations.find how_many, find_options
      result.is_a?(Array) ? result : [result]
    end

    def capture_change(record, down_version, up_version)
      return if down_version == up_version
      @changes << @operations.new_change(
        :obj_class_name => record.class.name,
        :obj_id         => record.attributes[record.class.primary_key],
        :down_version   => down_version,
        :up_version     => up_version,
        :obj_desc       => (record.respond_to?(:obj_desc) ? record.obj_desc : nil))
    end

    def push_changes(attrs = {})
      if @changes.size > 0
        attrs[:description] = @changes.last.change_desc unless attrs[:description]
        @operations.push(@changes, attrs)
      end
    end
  end
end
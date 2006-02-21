# Copyright (c) 2006 Ian White
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

module Ardes #:nodoc:
  
  #
  # ==Framework for managing 'undoable' commands.
  #
  # AbstractItem and AbstractStack are mixins to provide the Item and Stack
  # interface and general behaviour.
  #
  # Manager is the heart of the undo framework.  You may use this class 'as is'
  # or descend from it to provide more functionality.  Ardes::ActiveRecord::Acts::Undo::Manager
  # is an example: it implements undoables by being a callback object for ActiveRecord::Base,
  # implements virtual atomic undoables (a bunch of undoables being treated as one undoable), and
  # also adds a 'description' to undoables.
  #
  # ===Example of use:
  #  class MyUndoItem
  #    include Ardes::Undo::AbstractItem
  #
  #    def initialize(name); @name = name; end
  #    def inspect; "Item: #{@name}"; end
  #
  #  protected
  #    def on_undo; p "#{@name} undone"; true; end
  #    def on_redo; p "#{@name} redone"; true; end
  #  end
  #
  #  class MyUndoStack
  #    include Ardes::Undo::AbstractStack
  #
  #    def initialize; @storage = Hash.new; @idx = 0; end
  #    def delete_undone_items; @storage.delete_if{|k,i| i.undone?}; end
  #    def push_item(item); @storage[@idx += 1] = item; @idx; end
  #    def update_item(id, item); @storage[id] = item; end
  #
  #    def each_id_item(reverse = false)
  #      list = @storage.sort
  #      list.reverse! if reverse
  #      list.each { |id, item| yield id, item}
  #    end
  #  end
  #
  #  m = Ardes::Undo::Manager.new MyUndoStack.new
  #  
  #  m.push MyUndoItem.new("first")   => 1
  #  m.push MyUndoItem.new("second")  => 2
  #   
  #  m.undoables      => [[2, Item: second], [1, Item: first]]
  #  
  #  m.undo           => [[2, Item: second]]
  #  "second undone"
  #  
  #  m.undo           
  #  "first undone"   => [[1, Item: first]]
  #  
  #  m.undoables      => []
  #
  #  m.redoables      => [[1, Item: first], [2, Item: second]]
  #
  #  m.redo :all      
  #  "first redone"
  #  "second redone"  => [[1, Item: first], [2, Item: second]]
  #
  #  m.undo :first
  #  "second undone"  => [[2, Item: second]]
  #
  #  m.push MyUndoItem.new("third")   => 3
  #
  #  m.undoables      => [[3, Item: third], [1, Item: first]]
  #
  # Notice that the undone item (item 2) was removed from the stack when a new item was pushed.
  module Undo
    # Error raised when undo() is called on an item that is already undone
    class ItemUndone < RuntimeError; end
    
    # Error raised when redo() is called on an item that has not been undone
    class ItemNotUndone < RuntimeError; end
    
    # == Abstract Undo Item
    #
    # Note: for flexibility the undone? and undone= methods are not defined here.
    # You need to define undone? and undone= in concerete implementation
    module AbstractItem
      
      def undo
        raise ItemUndone if self.undone?
        self.undone = true if result = on_undo
        result
      end
    
      def redo
        raise ItemNotUndone unless self.undone?
        self.undone = false if result = on_redo
        result
      end
    
    protected
      def on_undo; raise 'Must implement on_undo()'; end
      def on_redo; raise 'Must implement on_redo()'; end
    end
    
    #
    # == Abstract Stack specification
    # 
    # You must implement this interface in the stack object that you pass to Manager.
    #
    # NB. Method names are wordy to avoid method namespace clashes, as the stack is
    # likely to be a method-rich object like an ActiveRecord class.
    #
    module AbstractStack
      # Push a new undo item onto the stack, and return its stack id.
      def push_item(item); raise 'Must implement push_item'; end
    
      # Delete all undone commands.
      def delete_undone_items; raise 'Must implement delete_undone_items'; end
      
      # return the item with stack_id
      # optionally takes a block, if so, the block is yielded with the item and item saved
      def item_at(id); raise 'Must implement item_at'; end;
                  
      # Iterate through each item in order of addition (push order).  Takes a block which is passed |stack_id, item|.
      # Optional argument reverse (true or :reverse) iterates in reverse order (pop order).
      def each_id_item(reverse=false, &block); raise 'Must implement each_id_item'; end
        
      # Returns item stack_ids in an array
      # Arguments:
      #   undone  :undone|true | :not_undone|false  (default = nil, which means neither)
      #   to      :first|:all|Integer stack id      (default = :all)
      # 
      # If undone is :undone|true, then the order of the items is revered.  This is so that
      # items are returned in the order they should be processed
      #
      # This method depends on each_id_item, which is trivial to implement in many cases.
      # However, in the case of a database driven stack, it may be more efficient to override
      # this method and implement each_id_item using this method.
      def item_ids(undone = nil, to = :all)
        undone = true if undone == :undone
        undone = false if undone == :not_undone
        compare = (undone ? '<=' : '>=')
        result = Array.new
        each_id_item(undone==false) do |id, item|
          if undone.nil? or item.undone? == undone
            result << id
            unless to == :all
              break if to == :first or to.send(compare, id)
            end
          end
        end
        result
      end
        
    end
    
    #
    # == Undo Manager
    # 
    # This class manages the undoing/redoing of undoable items.  On creation pass
    # an object confirming to AbstractStack.
    #
    # This class provides only basic functionality.  See Ardes::ActiveRecord::Undo::Versioned::Manager
    # for an example of more functionality.
    #
    class Manager
      attr_reader :stack
      
      def initialize(stack)
        @stack = stack
      end
      
      def push(item)
        @stack.delete_undone_items
        @stack.push_item item
      end
      
      def undo(to = :first)
        if @stack.respond_to? :transaction
          @stack.transaction { undo_items to }
        else
          undo_items to
        end
      end

      def redo(to = :first)
        if @stack.respond_to? :transaction
          @stack.transaction { redo_items to }
        else
          redo_items to
        end
      end
      
      def undoables(to = :all)
        to = to[:to] if to.is_a? Hash
        if to.is_a? Array
          return [] if to.size == 0
          to = to.sort.first
        end
        @stack.item_ids :not_undone, to
      end
      
      def redoables(to = :all)
        to = to[:to] if to.is_a? Hash
        if to.is_a? Array
          return [] if to.size == 0
          to = to.sort.last
        end
        @stack.item_ids :undone, to
      end
    
    protected
      def undo_items(to)
        undoables(to).each { |id| @stack.item_at(id) {|item| item.undo}}
      end
      
      def redo_items(to)
        redoables(to).each { |id| @stack.item_at(id) {|item| item.redo}}
      end
    end
  end
end

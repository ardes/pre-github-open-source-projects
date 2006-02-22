require 'ardes/undo'

module Ardes# :nodoc:
  module Undo# :nodoc:
    #
    # == Undo Item and Stack for ActiveRecord
    #
    # The stack is the class, and the item is the ActiveRecord object
    #
    module ActiveRecord
      def self.included(base) # :nodoc:
        super
        base.class_eval do
          extend SingletonMethods
          include InstanceMethods
          cattr_accessor :undone_column
          self.undone_column = "undone"
        end
      end
      
      module SingletonMethods
        include Ardes::Undo::AbstractStack
        
        def delete_undone_items
          delete_all(undone_column << " = 1")
        end

        def push_item(item)
          item.save!
          item.attributes[primary_key]
        end
        
        def item_at(pkId)
          return unless item = find(pkId)
          if block_given?
            yield item 
            item.save
          end
        end

        def each_id_item(reverse = false)
          ids = self.item_ids
          ids.reverse! if reverse
          ids.each {|id| yield(id, find(id)) }
        end

        # See Ardes::Undo::AbstractStack.items
        def item_ids(undone = nil, to = :all)
          undone = true if undone == :undone
          undone = false if undone == :not_undone
    
          conditions = []
          conditions << "#{primary_key} #{undone == false ? '>=' : '<='} #{to}" if to.is_a? Integer
          conditions << "#{undone_column} = #{undone ? 1 : 0}" unless undone.nil?

          find_opts = {:order => "id #{undone == false ? 'DESC' : 'ASC'}"}
          find_opts[:limit] = 1 if to == :first
          find_opts[:conditions] = [conditions.join(" and ")] if conditions.size > 0

          find(:all, find_opts).collect {|r| r.id}
        end
      end
      
      module InstanceMethods
        include Ardes::Undo::AbstractItem
      end
    end
  end
end
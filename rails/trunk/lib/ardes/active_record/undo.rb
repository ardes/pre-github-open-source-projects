require 'ardes/undo'

module Ardes# :nodoc:
  module ActiveRecord# :nodoc:
    #
    # == Undo Item and Stack for ActiveRecord
    #
    # The stack is the class, and the item is the ActiveRecord object
    #
    module Undo
      def self.included(base) # :nodoc:
          base.extend ClassMethods
      end

      module ClassMethods
        def acts_as_undo_stack(options={})
          class_eval { extend SingletonMethods }
          include InstanceMethods
          cattr_accessor :undone_column
          self.undone_column = options[:undone_column]  || "undone"
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

        def update_item(pkId, item)
          to_update = find(pkId)
          to_update.attributes = item.attributes
          to_update.save!
        end

        def each_item(reverse = false, &block)
          item_list = items
          item_list.reverse! if reverse
          item_list.each(&block)
        end

        # See Ardes::Undo::AbstractStack.items
        def items(undone = nil, to = :all)
          undone = true if undone == :undone
          undone = false if undone == :not_undone
    
          conditions = []
          conditions << "#{primary_key} #{undone == false ? '>=' : '<='} #{to}" if to.is_a? Integer
          conditions << "#{undone_column} = #{undone ? 1 : 0}" unless undone.nil?

          find_opts = {:order => "id #{undone == false ? 'DESC' : 'ASC'}"}
          find_opts[:limit] = 1 if to == :first
          find_opts[:conditions] = [conditions.join(" and ")] if conditions.size > 0

          find(:all, find_opts).collect {|r| [r.id, r]}
        end
      end
      
      module InstanceMethods
        include Ardes::Undo::AbstractItem
      end
    end
  end
end

ActiveRecord::Base.class_eval { include Ardes::ActiveRecord::Undo }


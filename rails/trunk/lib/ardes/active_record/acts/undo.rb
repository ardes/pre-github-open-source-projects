require 'ardes/undo/versioned/grouping'

module Ardes# :nodoc:
  module ActiveRecord# :nodoc:
    module Acts# :nodoc:
      #
      # Specify this act to enable unodable operations on your ActiveRecord models
      #
      # ===Example of use
      #
      #   class MyProduct < ActiveRecord::Base
      #     acts_as_undoable :products
      #     has_many :my_parts, :dependent => true
      #   end
      # 
      #   class MyPart < ActiveRecord::Base
      #     acts_as_undoable :products
      #     belongs_to: my_product
      #   end
      #
      #   @manager = MyProduct.undo_manager
      #   c = nil
      #
      #   # start with a new chandelier
      #   chandelier_created_with_gold_leaf = @manager.execute do
      #     c = MyProduct.create(:name => 'chandelier')
      #     c.my_parts << (MyPart.new(:name => 'gold leaf'))
      #     c.save
      #   end
      #   
      #   # add some glass beads
      #   glass_beads_added = @manager.execute do
      #     c.my_parts << (MyPart.new(:name => 'glass bead'))
      #     c.my_parts << (MyPart.new(:name => 'glass bead'))
      #     c.save
      #   end
      #   
      #   # now junk the chandelier (and the dependent parts)
      #   chandelier_destroyed = @manager.execute do
      #     FineProduct.find(c.id).destroy
      #   end
      #   
      #   # We now have nothing, but along the way a chandelier with 1 part was created
      #   # and then two new parts were added to that
      #
      #   # NOW, lets undo some of that
      #   
      #   @manager.undo glass_beads_added # will undo the destroy, and the glass_beads
      #   
      #   @manager.redo glass_beads_added # add the beads again
      #   
      #   # getting rid of chandelier will undo all ops to that point, which means no hanging foriegn keys
      #   @manager.undo chandelier_created_with_gold_leaf  
      #
      module Undo

        def self.included(base)
          base.extend(ClassMethods)
        end

        module ClassMethods
          def acts_as_undoable(*args, &extension)
            options = args.last.is_a?(Hash) ? args.pop : {}
            scope = (args.pop or :application)
            
            cattr_accessor :undo_manager
            self.undo_manager = Manager.for(scope, *(options[:manager] ? options[:manager] : Array.new) )
            self.undo_manager.manage(self)
            
            acts_as_versioned(options, &extension)
                        
            include ActMethods
          end
        end

        module ActMethods
          
          # Executes the block in an undoable context, using the
          # reciever's undo_manager to execute the block
          def undoable(&block)
            undo_manager.execute(&block)
          end
          
          # send the named method to the reciever in an undoable context, using the
          # reciever's undo_manager to execute the block
          def send_undoable(methodname, *args)
            undo_manager.execute {self.send(methodname, *args)}
          end
        end
        
        class Manager < Ardes::Undo::Versioned::Grouping::Manager

        end
      end
    end
  end
end

ActiveRecord::Base.class_eval { include Ardes::ActiveRecord::Acts::Undo }


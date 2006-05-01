module Ardes
  module ActionView
    module Helpers
      module Modal
        def link_to(*args, &block)
          modalize_link(args[0], args[2], &block) or super(*args)
        end

        def link_to_function(*args, &block)
          modalize_link(args[0], args[2], &block) or super(*args)
        end
        
        def link_to_remote(*args, &block)
          modalize_link(args[0], args[2], &block) or super(*args)
        end
        
        def submit_tag(*args, &block)
          attributes = modalize_form_control_attributes(args[1], &block)
          args[1] = attributes if attributes
          super(*args)
        end
        
        def select_tag(*args, &block)
          attributes = modalize_form_control_attributes(args[2], &block)
          args[2] = attributes if attributes
          super(*args)
        end
        
      private
        
        def modalize_form_control_attributes(attributes, &block)
          if @modal and (!block_given? or yield(block))
            attributes = (attributes or Hash.new)
            attributes[:disabled] = true
          end
          attributes
        end
          
        def modalize_link(content, attributes, &block)
          if @modal and (!block_given? or yield(block))
            attributes = (attributes or Hash.new)
            attributes[:class] = attributes[:class].nil? ? 'modal' : attributes[:class] + ' modal'
            content_tag('span', content, attributes)
          else
            false
          end
        end
      end
    end
  end
end

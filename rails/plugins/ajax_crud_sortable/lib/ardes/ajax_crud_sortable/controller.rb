module Ardes
  module AjaxCrudSortable
    module Controller
      def ajax_crud_sortable(options = {})
        raise 'ajax_crud_sortable requires ajax_crud' unless self.included_modules.include?(Ardes::AjaxCrud::Controller::Actions)
        include Actions
        include InstanceMethods
        cattr_accessor :sortable_order
        self.sortable_order = options[:order] || "#{model_sym.to_s.tableize}.position"
        inherit_views :ajax_crud_sortable
      end
      
      module InstanceMethods
        def self.included(base)
          base.class_eval { alias_method_chain :load_model_list, :sortable }
        end
        
      private
        def load_model_list_with_sortable
          self.model_class.with_scope(:find => {:order => self.sortable_order}) do
            load_model_list_without_sortable
          end
        end
      end

      module Actions
        def sortable
          @sorting = params[:sort]
          @models = model_list
        end

        def sort
          params["#{public_id}_sortable_list".to_sym].each_with_index do |id, position|
            self.model_class.update(id, :position => position)
          end
          render_nothing
        end
      end
    end
  end
end

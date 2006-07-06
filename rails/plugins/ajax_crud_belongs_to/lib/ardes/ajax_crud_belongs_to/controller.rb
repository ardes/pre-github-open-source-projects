module Ardes
  module AjaxCrudBelongsTo
    module Controller  
      def ajax_crud_belongs_to(association = nil, options = {})
        raise 'ajax_crud_belongs_to requires ajax_crud' unless self.included_modules.include?(Ardes::AjaxCrud::Controller::Actions)
    
        unless self.included_modules.include?(Ardes::AjaxCrudBelongsTo::Controller::InstanceMethods)
          include InstanceMethods
          extend ClassMethods
          cattr_accessor :belongs_to_associations
          self.belongs_to_associations = []
          inherit_views :ajax_crud_belongs_to
          before_filter :load_belongs_to
        end
        
        add_belongs_to_association(association, options) if association
      end
  
      module InstanceMethods  
        def self.included(base)
          base.class_eval do
            alias_method_chain :edit,             :belongs_to
            alias_method_chain :default_params,   :belongs_to
            alias_method_chain :load_model_list,  :belongs_to
          end
        end

        def edit_with_belongs_to
          params[:model].merge!(belongs_to_conditions) if params[:model]
          edit_without_belongs_to
        end    

        def default_params_with_belongs_to
          default_params_without_belongs_to.merge(belongs_to_conditions)
        end
    
      private
        def belongs_to_conditions
          conditions = {}
          self.belongs_to_associations.each do |assoc|
            conditions[assoc[:id_field]]   = @belongs_to[assoc[:sym]].id
            conditions[assoc[:type_field]] = @belongs_to[assoc[:sym]].class.name if assoc[:type_field]
          end
          conditions
        end
        
        def load_model_list_with_belongs_to
          self.model_class.with_scope(:find => {:conditions => belongs_to_conditions}) do
            load_model_list_without_belongs_to
          end
        end
          
        def load_belongs_to
          @belongs_to = {}
          self.belongs_to_associations.each do |assoc|
            belongs_to_class = assoc[:class] || params[assoc[:type_field]].constantize
            @belongs_to[assoc[:sym]] = belongs_to_class.find(params[assoc[:id_field]])
            instance_variable_set "@#{assoc[:sym]}", @belongs_to[assoc[:sym]]
          end
        end
      end
  
      module ClassMethods
        def add_belongs_to_association(association, options = {})
          assoc = {}
          assoc[:sym]         = association
          assoc[:id_field]    = association.to_s.foreign_key.to_sym
          assoc[:class]       = association.to_s.classify.constantize unless options[:polymorphic]
          assoc[:type_field]  = "#{association}_type".to_sym if options[:polymorphic]
          self.belongs_to_associations << assoc
        end
        
        def controller_id(url = {})
          controller_id = controller_name
          self.belongs_to_associations.each do |assoc|
            controller_id += "_#{url[:params][assoc[:id_field]]}"
            controller_id += "_#{url[:params][assoc[:type_field]]}" if assoc[:type_field]
          end
          controller_id
        end
      end
    end
  end
end

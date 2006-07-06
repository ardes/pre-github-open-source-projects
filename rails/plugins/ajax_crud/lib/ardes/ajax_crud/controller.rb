require 'ardes/ajax_crud/helper'

#
# TODO: make the controller set an instance var @model_name and also use this
# for params
#
module Ardes
  module AjaxCrud
    module Controller
      def ajax_crud(model = nil)
        include Actions
        include InstanceMethods
        extend ClassMethods

        cattr_accessor :model_sym, :model_class, :model_name
        set_model(model) if model
        
        helper Ardes::AjaxCrud::Helper
        
        inherit_views :ajax_crud
      end

      module Actions
        def index
          model_list
          respond_to(:html, :js)
        end
        
        def show
          @model = self.model_class.find(params[:id])
          render :action => 'open'
        end
        
        def destroy
          @model = self.model_class.find(params[:id])
          if @model.destroy
            @message = "#{model_desc} destroyed"
          end
        end
        
        def edit
          @model = self.model_class.find_by_id(params[:id]) || self.model_class.new
          @new_record = @model.new_record?
          if params[:model]
            @model.attributes = params[:model]
            if @model.save
              @message = model_desc + (@new_record ? ' created' : ' updated')
              render :action => 'edit'
            else
              render :action => 'error'
            end
          else
            render :action => 'open'
          end
        end
      end
      
      module InstanceMethods
        def self.included(base)
          methods = self.public_instance_methods
          base.class_eval { hide_action(*methods) }
        end

        def public_id(url = {})
          self.class.generate_public_id(internal_url(url))
        end

        def model_desc(model = @model)
          model.respond_to?(:obj_desc) ? model.obj_desc : "#{self.model_name}: #{model.id}"
        end

        def model_list(reload = false)
          @models = nil if reload
          @models ||= load_model_list
        end
        
        def model_count(reload = false)
          @model_count = nil if reload
          @model_count ||= load_model_list.size
        end
        
        def internal_url(url)
          url = self.class.sanitize_url(url)
          url[:params].merge!(default_params)
          url
        end
      
      private
        def load_model_list
          self.model_class.find_all
        end
        
        def default_params
          {}
        end
      end
    
      module ClassMethods
        def set_model(model)
          self.model_sym   = model
          self.model_name  = model.to_s.humanize.downcase
          self.model_class = model.to_s.classify.constantize
        end
        
        def public_id(url = {})
          generate_public_id(sanitize_url(url))
        end
        
        def sanitize_url(url)
          url = url.dup
          sanitized = {}
          sanitized[:controller] = url.delete(:controller) if url[:controller]
          sanitized[:action] = url.delete(:action) if url[:action]
          sanitized[:params] = url.delete(:params) || {}
          sanitized[:params].merge!(url)
          sanitized
        end
        
        def controller_id(url = {})
          self.controller_name
        end
        
        def generate_public_id(url)
          public_id  = controller_id(url)
          public_id += "_#{url[:params][:id]}" if url[:params][:id]
          public_id += "_#{url[:action]}"      if url[:action]
          public_id
        end
      end
    end
  end
end
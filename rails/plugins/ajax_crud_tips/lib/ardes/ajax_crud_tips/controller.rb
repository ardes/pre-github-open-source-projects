require 'ardes/ajax_crud/form_builder'

module Ardes
  module AjaxCrudTips
    module Controller
      def ajax_crud_tips(tips_hash)
        raise 'ajax_crud_tips requires ajax_crud' unless self.included_modules.include?(Ardes::AjaxCrud::Controller::Actions)
        cattr_accessor :ajax_crud_tips
        self.ajax_crud_tips = tips_hash
        helper Ardes::AjaxCrudTips::Helper
      end
    end
      
    module Helper
      def self.included(base)
        base.class_eval { alias_method_chain :form_for_action, :tips }
      end
      
      def form_for_action_with_tips(url, options = {}, &block)
        options[:builder] ||= Ardes::AjaxCrudTips::FormBuilder
        form_for_action_without_tips(url, options, &block)
      end
      
      def tip_for(attribute)
        return unless tip = controller.ajax_crud_tips[attribute]
        
        if tip.is_a? String
          eval "\"#{tip}\""
        elsif tip.is_a? Proc
          call tip(controller)
        end
      end
    end
    
    class FormBuilder < Ardes::AjaxCrud::FormBuilder
      def extract_options_and_render_tag(method, options = {}, &block)
        options[:tip] = @template.tip_for(method) unless options[:tip]
        super(method, options, &block)
      end
    end
  end
end
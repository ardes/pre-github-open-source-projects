module Ardes
  module AjaxCrud
    module Helper
      def loading_link(content, options = {}, html_options = {})
        add_loading(options)
        html_options[:onclick] = "#{confirm_link_to}#{html_options[:onclick]}" if options.delete(:safe)
        link_to_remote(content, options, html_options)
      end
      
      def internal_link(content, options = {}, html_options = {})
        options[:url] = internal_url(options[:url])
        loading_link(content, options, html_options)
      end
      
      def internal_url(url)
        controller.internal_url(url)
      end
        
      def safe_link_to(content, options = {}, html_options = {})
        html_options[:onclick] = "#{confirm_link_to}#{html_options[:onclick]}"
        link_to(content, options, html_options)
      end

      def open_action(content, url, options = {})
        html_options = options.delete(:html) || {}
        html_options[:class] = options.delete(:class) || 'action'
        add_loading(options)
        options[:url] = internal_url(url)
        action_id = public_id(url);
        options[:before]  = "Element.hide('#{action_id}_open');" + "Element.show('#{action_id}_goto');"
        # create action link
        out =  link_to_remote(content, options, html_options.merge({:id => "#{action_id}_open"}))
        # and create a goto link which is hidden, but turned one when the action is open
        out << link_to_function(content, "ArdesAjaxCrud.focus('#{action_id}');", html_options.merge({:id => "#{action_id}_goto", :style => "display:none;"}))
      end

      def cancel_action(content, url, options = {})
        html_options = options.delete(:html) || {}
        html_options[:class] = options.delete(:class) || 'action'
        html_options[:onclick] = "#{confirm_link_to}#{html_options[:onclick]}" if options.delete(:safe)
        add_loading(options)
        options[:url] = {:action => 'cancel'}
        options[:url][:id] = url[:id] if url[:id]
        options[:url][:params] = url[:params] || {}
        options[:url][:params][:cancel] = url[:action]
        options[:url] = internal_url(options[:url])
        link_to_remote(content, options, html_options)
      end

      def form_for_action(url, options = {}, &block)
        add_loading(options)
        options[:url] = internal_url(url)
        options[:before] = "Form.disable('#{public_id(url)}_form');"
        options[:html] ||= {}
        options[:html][:id] = "#{public_id(url)}_form"
        options[:builder] ||= Ardes::AjaxCrud::FormBuilder
        form_remote_for('model', @model, options, &block)
      end

      def public_id(url = {})
        if url[:controller] && url[:controller] != controller.controller_name
          controller_class = "#{url[:controller]}_controller".classify.constantize
          controller_class.public_id(url)
        else
          controller.public_id(url)
        end
      end
      
      def rjs_message(page, message, options = {})
        message_div = "#{public_id(options)}_message"
        page.replace_html message_div, message.to_s
        page.delay(0.5) { page.visual_effect :appear, message_div, {:duration => 0.5, :queue => {:position => 'end', :scope => 'message'}}}
        page.delay(3)   { page.visual_effect :fade,   message_div, {:queue => {:position => 'end', :scope => 'message'}} }
      end

      def rjs_open(page, options)
        action_id = public_id(options)
        action = options.delete(:action)
        container_id = options.delete(:container_id) || public_id(options)
        page.insert_html :top, container_id, "<div id=\"#{action_id}\" class=\"action\"></div>"
        page.replace_html action_id, :partial => action
        page << "ArdesAjaxCrud.focus('#{action_id}');"
        page << "ArdesAjaxCrud.observe('#{action_id}');"
      end

      def rjs_close(page, options)
        action_id = public_id(options)
        page << "ArdesAjaxCrud.setClean('#{action_id}');"
        page.show "#{action_id}_open"
        page.hide "#{action_id}_goto"
        page.remove action_id
      end

      def rjs_error(page, options)
        action_id = public_id(options)
        page.replace_html action_id, :partial => options[:action]
        page.visual_effect :highlight, action_id, {:duration => 0.25, :startcolor => '"#FFDDDD"', :queue => 'front'}
        page << "ArdesAjaxCrud.focus('#{action_id}');"
      end

      def rjs_update_item(page, item, new_record, options = {})
        if new_record # append to list
          rjs_append_item(page, item, options)
        else # update item in list
          rjs_refresh_item(page, item, options)
        end
      end
      
      def rjs_remove_item(page, item, options = {})
        list_id = "#{public_id(options)}_list"
        options[:id] = item.id
        item_id = "#{public_id(options)}_item"
        
        page.insert_html :top, list_id, :partial => "list_empty" if controller.model_count == 0
        page.remove item_id
        page.visual_effect :highlight, list_id
      end
        
      def rjs_refresh_item(page, item, options = {})
        options[:id] = item.id
        item_id = "#{public_id(options)}_item"
        item_main_id = "#{item_id}_main"
        page.replace_html item_main_id, :partial => 'item_main', :locals => {:item => item}
        page.visual_effect :highlight, item_id
      end

      def rjs_append_item(page, item, options = {})
        public_id = public_id(options)
        
        list_id  = "#{public_id}_list"
        empty_id = "#{public_id}_list_empty"
        end_id   = "#{public_id}_list_end"
        
        options[:id] = item.id
        item_id = "#{public_id(options)}_item"

        page.remove end_id
        page.remove empty_id if controller.model_count == 1
        
        page.insert_html :bottom, list_id, :partial => 'item', :locals => {:item => item}
        page.insert_html :bottom, list_id, :partial => 'list_end'
        page.visual_effect :highlight, item_id
      end

    private
      def add_loading(options)
        loading_id = "#{public_id}_loading"
        options[:loading] = "Element.show('#{loading_id}');"
        options[:loaded]  = "Element.hide('#{loading_id}');"
      end
      
      def confirm_link_to
        "if (! ArdesAjaxCrud.confirm()) {return false;}"
      end
    end
  end
end
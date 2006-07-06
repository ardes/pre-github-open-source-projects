module Ardes
  module AjaxCrud
    class FormBuilder < ::ActionView::Helpers::FormBuilder
      field_helpers.each - ['hidden_field'] do |selector|
        src = <<-end_src
          def #{selector}(method, options = {})
            extract_options_and_render_tag(method, options) do |method, options|
              super(method, options)
            end
          end
        end_src
        class_eval src, __FILE__, __LINE__
      end
    
      def input(method, options = {})
        extract_options_and_render_tag(method, options) do |method, options|
          @template.send :input, @object_name, method, options
        end
      end
      
      def summary(method, options = {})
        label = options.delete(:label) || method.to_s.humanize
        tip = options.delete(:tip)
        tip = "<div class=\"tip\">#{tip}</div>" if tip
        <<-end_summary
          <div class="summary">
            <div class="label">#{label}:</div>
            <div class="content">#{@object.send(method)} &nbsp;</div>
            #{tip}
          </div>
        end_summary
      end
      
      def errors_base(message = "There are errors in this form preventing it from being saved.  Please correct the marked fields below.")
        unless @object.errors.empty?
          if errors = @object.errors.on_base
            errors = errors.is_a?(Array) ? errors : [errors]
            errors = "<div class=\"error\">#{errors.join('<br />')}</div>"
          end
          <<-end_error_message
            <div class="error">
              #{message}
              #{errors}
            </div>
          end_error_message
        end
      end
      
    private
      def extract_options_and_render_tag(method, options = {}, &block)
        tip = options.delete(:tip)
        label = options.delete(:label) || method.to_s.humanize
        tag = yield(method, options)
        if errors = @object.errors.on(method)
          errors = errors.is_a?(Array) ? errors : [errors]
        end
        render_field(method, tag, label, tip, errors)
      end
      
      def render_field(method, tag, label, tip, errors)
        errors = "<div class=\"error\">#{errors.join('<br />')}</div>" if errors
        tip = "<div class=\"tip\">#{tip}</div>" if tip
        <<-end_field
          <div class="field#{errors ? ' error' : ''}">
            <label for="#{@object_name}_#{method}">#{label}</label>
            #{tag}
            #{tip}
            #{errors}
          </div>
        end_field
      end
    end
  end
end
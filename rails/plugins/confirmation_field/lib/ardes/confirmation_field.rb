module ActionView::Helpers::FormHelper
  def confirmation_text_field(object_name, method, options = {})
    value = preload_confirmation_value(object_name, method)
    options[:value] = value unless value.nil?
    ::ActionView::Helpers::InstanceTag.new(object_name, "#{method}_confirmation".to_sym, self, nil, options.delete(:object)).to_input_field_tag("text", options)
  end

  def confirmation_password_field(object_name, method, options = {})
    value = preload_confirmation_value(object_name, method)
    options[:value] = value unless value.nil?
    ::ActionView::Helpers::InstanceTag.new(object_name, "#{method}_confirmation".to_sym, self, nil, options.delete(:object)).to_input_field_tag("password", options)
  end

private
  # if 'attr_confirmation' is nil, then return the value of 'attr'
  def preload_confirmation_value(object_name, method)
    object = eval "@#{object_name}"
    if nil == (object.respond_to?("#{method}_confirmation_before_type_cast") ? object.send("#{method}_confirmation_before_type_cast") : object.send("#{method}_confirmation"))
      object.respond_to?("#{method}_before_type_cast") ? object.send("#{method}_before_type_cast") : object.send(method)
    else
      nil
    end
  end
end

class ActionView::Helpers::FormBuilder
  def confirmation_text_field(method, options = {})
    @template.send(:confirmation_text_field, @object_name, method, options.merge(:object => @object))
  end

  def confirmation_password_field(method, options = {})
    @template.send(:confirmation_password_field, @object_name, method, options.merge(:object => @object))
  end
end

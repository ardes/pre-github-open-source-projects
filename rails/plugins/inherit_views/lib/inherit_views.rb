module ActionController::InheritViews
  def self.included(base)
    base.class_eval do
      cattr_accessor :inherit_views_from
      extend ClassMethods
    end
  end
  
  module ClassMethods
    # specify this to have your controller inherit its view from the specified controllers
    def inherit_views(*controllers)
      self.inherit_views_from = controllers
    end
  end
end

ActionController::Base.class_eval { include ActionController::InheritViews }

class ActionView::Base
private
  def full_template_path(template_path, extension)
    # If the template exists in the normal application directory, return that path
    full_path = "#{@base_path}/#{template_path}.#{extension}"
    return full_path if File.exist?(full_path)

    # Otherwise, check in any additional template paths in order
    if controller.inherit_views_from
      controller.inherit_views_from.each do |from|
        inherited_template_path = template_path.sub /^.*\//, from.to_s + '/'
        inherited_full_path = "#{@base_path}/#{inherited_template_path}.#{extension}"
        if File.exist?(inherited_full_path)
          logger.debug("Found inherted view #{inherited_template_path}")
          return inherited_full_path
        end
      end
    end

    # If it cannot be found in additional paths, return the default path
    return full_path
  end
end

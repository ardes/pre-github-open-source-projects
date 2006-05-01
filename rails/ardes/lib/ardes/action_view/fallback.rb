module Ardes
  module ActionView
    #
    # Allows specification of a fallback dir to look for a file template
    #
    # This is useful if you are subclassing a controller and just want to
    # override just a few of the view tmeplates
    # 
    # To set the fallback call 'fallback_path =' on the template
    #
    # To set it glabablly for a controller do this in you controller
    #
    #   def initialize_template_class(response)
    #     super(response)
    #     response.template.fallback_path = 'your_fallback_path'
    #   end
    #
    module Fallback
      def self.included(base)
        super
        
        base.send :alias_method, :render_file_without_fallback, :render_file
        base.send :alias_method, :render_file, :render_file_with_fallback
        
        base.send :alias_method, :file_exists_without_fallback?, :file_exists?
        base.send :alias_method, :file_exists?, :file_exists_with_fallback?
      end
      
      attr_accessor :fallback_path
    
      def render_file_with_fallback(template_path, *args)
        unless file_exists_without_fallback?(template_path)
          template_path.sub! /^.*\//, @fallback_path.to_s + '/'
        end
        render_file_without_fallback(template_path, *args)
      end
          
      def file_exists_with_fallback?(template_path)
        return true if file_exists_without_fallback?(template_path)
        template_path.sub! /^.*\//, @fallback_path.to_s + '/'
        file_exists_without_fallback?(template_path)
      end
    end
  end
end

ActionView::Base.class_eval { include Ardes::ActionView::Fallback }
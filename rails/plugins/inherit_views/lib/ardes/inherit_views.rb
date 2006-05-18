module Ardes# :nodoc:
  module ActionController# :nodoc:
    module InheritViews
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
  end
end

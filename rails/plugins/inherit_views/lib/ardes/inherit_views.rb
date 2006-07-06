module Ardes# :nodoc:
  module ActionController# :nodoc:
    module InheritViews
      def self.included(base)
        base.class_eval do
          class_inheritable_accessor :inherit_views_from
          self.inherit_views_from = []
          extend ClassMethods
          include InstanceMethods
        end
      end
      
      module InstanceMethods
        def exclude_views_for(controller, &block)
          original = self.inherit_views_from.dup
          self.inherit_views_from.delete(controller)
          yield
          self.inherit_views_from = original
        end
        
        def parent_views_for(controller, &block)
          original = self.inherit_views_from.dup
          if i = self.inherit_views_from.index(controller)
            self.inherit_views_from.slice!(0..i)
          end
          yield
          self.inherit_views_from = original
        end
      end
      
      module ClassMethods
        # specify this to have your controller inherit its view from the specified controllers
        # or the current controller if no argument is given
        def inherit_views(*controllers)
          controllers = [self.controller_name.to_sym] if controllers.size == 0
          self.inherit_views_from -= controllers
          self.inherit_views_from = controllers + self.inherit_views_from
        end
      end
    end
  end
end

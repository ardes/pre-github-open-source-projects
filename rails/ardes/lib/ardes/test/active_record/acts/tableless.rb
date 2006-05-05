module Ardes# :nodoc:
  module Test# :nodoc:
    module ActiveRecord# :nodoc:
      module Acts# :nodoc:
        #
        # To use this mixin do this
        #
        # class MyTest < Test::Rails::TestCase
        #   test_acts_as_tableless :model
        # end
        #
        module  Ardes::Test::ActiveRecord::Acts::Tableless
          def self.included(base)
            base.extend(ClassMethods)
          end

          module ClassMethods
            def test_acts_as_tableless(target)
              include InstanceMethods
              self.class_eval do
                cattr_accessor :acts_as_tableless_class
                self.acts_as_tableless_class = target.to_s.classify.constantize
              end        
            end
          end

          module InstanceMethods
            def test_should_have_attributes_corresponding_to_columns
              obj = self.acts_as_tableless_class.new
              assert_equal obj.attributes.keys.sort, obj.class.columns.collect{|c| c.name}.sort
            end
    
            def test_should_make_new_object_on_create
              assert_kind_of self.acts_as_tableless_class, self.acts_as_tableless_class.create
            end
    
            def test_should_make_object_corresponding_to_attributes_on_update_attributes
              obj = self.acts_as_tableless_class.new
              attr = obj.attributes.keys.first
              obj.update_attributes(attr => '1')
              assert_equal '1', obj.attributes[attr].to_s
            end
    
            def test_should_not_raise_error_on_save
              self.acts_as_tableless_class.new.save
            end
          end
        end
      end
    end
  end
end

Test::Rails::TestCase.class_eval { include Ardes::Test::ActiveRecord::Acts::Tableless }

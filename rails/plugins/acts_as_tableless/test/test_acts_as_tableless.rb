# unit test extension for validatable mixin
#
# assumes that there are attribute accessors for the target class
#
module Test
  module Abstract
    module ActsAsTableless
      def self.included(base)
        base.extend ClassMethods
      end
  
      module ClassMethods
        def test_acts_as_tableless(target_class)
          include InstanceMethods
          cattr_accessor :acts_as_tableless_class
          self.acts_as_tableless_class = target_class
        end
      end
  
      module InstanceMethods
        def test_acts_as_tableless_should_have_attributes_corresponding_to_columns
          obj = self.acts_as_tableless_class.new
          assert_equal obj.attributes.keys.sort, obj.class.columns.collect{|c| c.name}.sort
        end

        def test_acts_as_tableless_should_make_new_object_on_create
          assert_kind_of self.acts_as_tableless_class, self.acts_as_tableless_class.create
        end

        def test_acts_as_tableless_should_make_object_corresponding_to_attributes_on_update_attributes
          obj = self.acts_as_tableless_class.new
          attr = obj.attributes.keys.first
          obj.update_attributes(attr => '1')
          assert_equal '1', obj.attributes[attr].to_s
        end

        def test_acts_as_tableless_should_not_raise_error_on_save
          self.acts_as_tableless_class.new.save
        end
      end
    end
  end
end
Test::Unit::TestCase.class_eval { include Test::Abstract::ActsAsTableless }
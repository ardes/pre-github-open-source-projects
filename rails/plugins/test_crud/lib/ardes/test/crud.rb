#
# To test basic crud operations on your active record do the following
# require 'ares/test/crud'
# class MyTest < Test::Unit::TestCase
#   test_crud ClassName, :a_fixture_name, {:an_attr => 'a val for create', ...}
# end
#
module Ardes
  module Test
    module Crud
      def self.included(base)
        super
        base.extend(ClassMethods)
      end

      module ClassMethods
        def test_crud(crud_class, crud_fixture, crud_attrs = nil)
          include InstanceMethods
          self.class_eval do
            cattr_accessor :crud_class, :crud_fixture, :crud_attrs
            self.crud_fixture = crud_fixture.to_s
            self.crud_class   = crud_class
            self.crud_attrs   = crud_attrs
          end
        end
      end

      module InstanceMethods
        # this test only checks read on non aggregate and non associate attributes
        # write your own tests for these
        def test_crud_should_perform_read
          fixture = send(self.crud_class.table_name, self.crud_fixture)
          object  = self.crud_class.find(fixture.id)

          assert_kind_of self.crud_class, object
          reflections = self.crud_class.reflections.keys
          self.crud_attrs.keys.each do |attr|
            assert_equal fixture[attr], object.send(attr) unless reflections.include? attr
          end
        end

        def test_crud_should_perform_create
          attrs = {}
          self.crud_attrs.each {|k, v| attrs[k] = v.is_a?(Proc) ? v.call : v }
          
          object = self.crud_class.create(attrs).reload

          assert_kind_of self.crud_class, object
          attrs.each do |attr, value|
            assert_equal value, object.send(attr)
          end
        end

        def test_crud_should_perform_update
          fixture = send(self.crud_class.table_name, self.crud_fixture)
          object  = self.crud_class.find(fixture.id)
          
          attrs = {}
          self.crud_attrs.each {|k, v| attrs[k] = v.is_a?(Proc) ? v.call : v }
          
          object.update_attributes(attrs)
          object.reload
          attrs.each do |attr, value|
            assert_equal value, object.send(attr)
          end
        end

        def test_crud_should_perform_destroy
          fixture = send(self.crud_class.table_name, self.crud_fixture)
          object  = self.crud_class.find(fixture.id)
          object.destroy
          assert_raise(::ActiveRecord::RecordNotFound) { self.crud_class.find(object.id) }
        end
      end
    end
  end
end

Test::Unit::TestCase.class_eval { include Ardes::Test::Crud }
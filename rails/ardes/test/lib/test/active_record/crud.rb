module Ardes::Test::ActiveRecord; end# :nodoc:

#
# To test basic crud operations on your active record do the following
#
# class MyTest < Test::Rails::TestCase
#   test_crud :tablename, :a_fixture_name, {:an_attr => 'a val for create', ...}
# end
#
module Ardes::Test::ActiveRecord::Crud
  def self.included(base)
    super
    base.extend(ClassMethods)
  end

  module ClassMethods
    def test_crud(crud_table, crud_fixture, crud_attrs = nil)
      include InstanceMethods
      self.class_eval do
        cattr_accessor :crud_class, :crud_fixture, :crud_table, :crud_attrs
        self.crud_table   = crud_table.to_s.tableize
        self.crud_fixture = crud_fixture.to_s
        self.crud_class   = crud_table.to_s.classify.constantize
        self.crud_attrs   = crud_attrs
      end
    end
  end

  module InstanceMethods
    def test_should_perform_crud_read
      fixture = send(self.crud_table, self.crud_fixture)
      object  = self.crud_class.find(fixture.id)

      assert_kind_of self.crud_class, object
      self.crud_attrs.keys.each do |attr|
        assert_equal fixture[attr], object.send(attr)
      end
    end

    def test_should_perform_crud_create
      object = self.crud_class.create(self.crud_attrs).reload

      assert_kind_of self.crud_class, object
      self.crud_attrs.each do |attr, value|
        assert_equal value, object.send(attr)
      end
    end

    def test_should_perform_crud_update
      object = self.crud_class.find_first

      object.update_attributes(self.crud_attrs)
      object.reload
      self.crud_attrs.each do |attr, value|
        assert_equal value, object.send(attr)
      end
    end

    def test_should_perform_crud_destroy
      obj = self.crud_class.find_first.destroy
      assert_raise(::ActiveRecord::RecordNotFound) { self.crud_class.find(obj.id) }
    end
  end
end

Test::Unit::TestCase.class_eval { include Ardes::Test::ActiveRecord::Crud }
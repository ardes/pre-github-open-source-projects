module Ardes
  module Test
    module HasEmail
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        # Usage: 
        #   test_has_email Class, :email_attr
        #   test_has_email Class, :email_attr, :another_email_attr
        #   test_has_email Class, :email_attr, ..., [fixture names]
        #
        # If fixture names are given then those fixtures will be tested,
        # if ommitted then all fixtures will be tested
        def test_has_email(target_class, *args)
          include InstanceMethods
          self.class_eval do
            cattr_accessor :has_email_class, :has_email_attrs, :has_email_fixtures
            self.has_email_fixtures = args.last.is_a?(Array) ? args.pop : nil
            self.has_email_class    = target_class
            self.has_email_attrs    = args
          end
        end
      end

      module InstanceMethods
        def test_has_email_should_read_emails_as_value_objects
          obj = self.has_email_class.find_first
          self.has_email_attrs.each do |attr|
            assert_kind_of Ardes::Email, obj.send(attr) unless obj.send(attr).nil?
          end
        end
        
        def test_has_email_should_validate_valid_data_in_fixtures
          if self.has_email_fixtures
            to_test = self.has_email_fixtures.collect do |fixture|
              fixture = send(self.has_email_class.table_name, fixture)
              self.has_email_class.find(fixture.id)
            end
          else
            to_test = self.has_email_class.find(:all)
          end
          to_test.each do |record|
            self.has_email_attrs.each do |attr|
              assert record.valid_for_attributes?(attr)
            end
          end
        end
  
        def test_should_validate_ian_at_ardes_dot_com_on_all_emails
          obj = self.has_email_class.new
          self.has_email_attrs.each do |attr|
            obj.send(attr.to_s + '=', Ardes::Email.new('ian@ardes.com'))
            assert obj.valid_for_attributes?(attr)
          end
        end
                
        def test_should_invalidate_ian_space_at_ardes_dot_com_on_all_emails
          obj = self.has_email_class.new
          self.has_email_attrs.each do |attr|
            obj.send(attr.to_s + '=', Ardes::Email.new('ian @ardes.com'))
            assert(!obj.valid_for_attributes?(attr))
          end
        end
      end
    end
  end
end

Test::Unit::TestCase.class_eval { include Ardes::Test::HasEmail }

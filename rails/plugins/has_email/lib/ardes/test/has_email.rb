module Ardes
  module Test
    module HasEmail
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        # Assumes that there is a valid data in the table
        def test_has_email(target_class, *attrs)
          include InstanceMethods
          self.class_eval do
            cattr_accessor :has_email_class, :has_email_attrs
            self.has_email_class = target_class
            self.has_email_attrs = attrs
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
        
        def test_has_email_should_validate_valid_data
          self.has_email_class.find(:all).each do |record|
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
                
        def test_should_invalidate_ian_space_at_ardes_dot_com_on_all_phones
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

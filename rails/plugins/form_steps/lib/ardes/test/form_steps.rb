module Ardes
  module Test
    module FormSteps
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        # Assumes that there is a valid data in the table
        def test_form_steps
          include InstanceMethods
        end
      end

      module InstanceMethods
        def test_form_steps_should_have_steps_session_var
          assert @controller.steps_session_var
        end
      end
    end
  end
end

Test::Unit::TestCase.class_eval { include Ardes::Test::FormSteps }

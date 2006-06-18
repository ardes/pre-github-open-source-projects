module Ardes
  module Test
    module FormStepsOrder
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        #test_form_steps_order({
        #    :name     => 'get index',
        #    :get      => [:index],
        #    :asserts  => '@step == :first'
        #  },{
        #    :name     => 'process_step :first',
        #    :get      => [:process_step, {:step => 'first'}],
        #    :asserts  => Proc.new {'step' => :second}
        #  },{
        #    :name     => 'process_step :second',
        #    :get      => [:process_step, {:step => 'second']},
        #    :assigns  => {'step' => :third}
        #  })
        def test_form_steps_order(*steps)
          include InstanceMethods
          cattr_accessor :form_steps_order
          self.form_steps_order ||= []
          self.form_steps_order << steps
        end
      end

      module InstanceMethods
        def test_form_steps_order
          self.form_steps_order.each {|steps| perform_form_steps_order(steps)}
        end
        
        def perform_form_steps_order(steps)
          last_session = nil
          steps.each do |step|
            step_session = step[:session] || {}
            step_assigns = step[:assigns] || {}
            step_asserts = step[:asserts] || []
            step_asserts = step_asserts.is_a?(Array) ? step_asserts : [step_asserts]
            
            setup
            
            # merge last session and any session in options
            @request.session = last_session if last_session
            step_session.each {|k,v| @request.session[k] = v }
            
            # send request
            if step[:post]
              post(*step[:post])
            elsif step[:get]
              get(*step[:get])
            end
            
            assert_response(step[:response] || :success)
            
            # assert that the expected assigns are all as they should be
            step_assigns.each do |key, val|
              assert_equal val, assigns[key], "#{step[:name]} expected #{val.inspect} for #{key}, but got #{assigns[key].inspect}}}"
            end
            
            # assert that the otyher expectations are met
            step_asserts.each do |assertion|
              if assertion.is_a?(String)
                assert @controller.instance_eval(assertion), "#{step[:name]} assertion: '#{assertion}' failed"
              else
                assert assertion.call(@controller), "#{step[:name]} assertion: '#{assertion.inspect}' failed"
              end
            end
            # keep the session for the next go
            last_session = @request.session.dup
          end
        end
      end
    end
  end
end

Test::Unit::TestCase.class_eval { include Ardes::Test::FormStepsOrder }

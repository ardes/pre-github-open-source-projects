# dependency: arts plugin (rjs testing)

require File.dirname(__FILE__) + '/test_helper'
require 'ardes/test/form_steps'

class FormStepsTestController < ActionController::Base
  form_steps :first, :second, :third
  
  self.template_root = File.dirname(__FILE__) + '/views'
  
  def blank
    render_nothing
  end
  
  def complete
    render_nothing
  end

protected
  def display_first
    @trace ||= Array.new
    @trace << :display_first
  end
  
  def first
    @trace ||= Array.new
    @trace << :process_first 
    if params[:skip_second]
      @trace << :skipping_second
      set_success(:second, true)
    end
  end
  
  def display_second
    @trace ||= Array.new
    @trace << :display_second
  end
  
  def second
    @trace ||= Array.new
    @trace << :process_second
  end
  
  def third
    @trace ||= Array.new
    @trace << :process_third
    if params[:back_to_first]
      @trace << :back_to_first
      self.next_step = :first
    end
  end
  
  def steps_complete
    @trace ||= Array.new
    @trace << :steps_complete
    super
  end
    
end

class FormStepsTest < Test::Unit::TestCase

  test_form_steps
  
  def setup
    @controller = FormStepsTestController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
  end
  
  def test_on_complete_redirect_to
    @controller.on_complete_redirect_to = {:action => 'complete'}
    @request.session[FormStepsTestController.steps_session_var] = {:first => true, :second => true, :third => nil}
    get :process_step, {:step => 'third'}
    assert_redirected_to :action => 'complete'
  end
  
  def test_on_complete_redirect_to_rjs
    @controller.on_complete_redirect_to = {:action => 'complete'}
    @request.session[FormStepsTestController.steps_session_var] = {:first => true, :second => true, :third => nil}
    xhr :get, :process_step, {:step => 'third'}
    assert_rjs :redirect_to, :action => 'complete'
  end
    
  def test_all_steps_no_params
    get :index
    assert_response :success
    assert_equal [:display_first], assigns['trace']
    assert_template 'first'
    
    @controller = FormStepsTestController.new
    get :process_step, {:step => 'first'}
    assert_response :success
    assert_equal [:process_first, :display_second], assigns['trace']
    assert_template 'second'

    @controller = FormStepsTestController.new
    get :process_step, {:step => 'second'}
    assert_response :success
    assert_equal [:process_second], assigns['trace']
    assert_template 'third'
    
    @controller = FormStepsTestController.new
    get :process_step, {:step => 'third'}
    assert_response :success
    assert_equal [:process_third, :steps_complete], assigns['trace']
    assert_template 'third'
  end
  
  def test_skip_second
    get :process_step, {:step => 'first', :skip_second => true}
    assert_response :success
    assert_equal [:process_first, :skipping_second], assigns['trace']
    assert_template 'third'
    
    @controller = FormStepsTestController.new
    get :index
    assert_response :success
    assert_template 'third'
  end
  
  def test_back_to_first
    @request.session[FormStepsTestController.steps_session_var] = {:first => true, :second => true, :third => nil}
    get :process_step, {:step => 'third', :back_to_first => true}
    assert_response :success
    assert_equal [:process_third, :back_to_first, :display_first], assigns['trace']
    assert_template 'first'
    
    @controller = FormStepsTestController.new
    get :process_step, {:step => 'first'}
    assert_response :success
    assert_equal [:process_first, :steps_complete], assigns['trace']
    assert_template 'third'
  end
  
  def test_success_and_success_equals
    get :blank
    test = self
        
    assert_equal nil,   @controller.success
    assert_equal nil,   @controller.success(:first)
    assert_equal nil,   @controller.success(:second)
    assert_equal nil,   @controller.success(:third) 
    
    @controller.instance_eval { self.success = true }

    assert_equal true,  @controller.success
    assert_equal true,  @controller.success(:first)
    assert_equal nil,   @controller.success(:second)
    assert_equal nil,   @controller.success(:third) 

    @controller.instance_eval { set_success(:second, false) }
    
    assert_equal true,  @controller.success
    assert_equal true,  @controller.success(:first)
    assert_equal false, @controller.success(:second)
    assert_equal nil,   @controller.success(:third)
    
    @controller.instance_eval { self.current_step = :second }
    assert_equal false, @controller.success

    @controller.instance_eval { self.current_step = :third }
    assert_equal nil,  @controller.success    
  end
  
  def test_current_step_and_next_step_with_blank_session
    get :blank
    
    assert_equal :first,  @controller.current_step
    assert_equal :first,  @controller.next_step # because :first is not succesful
    
    @controller.instance_eval { self.success = true }

    assert_equal :second, @controller.next_step # because :first is succesful    
  end
    
  def test_current_step_and_next_step_with_session_first_true
    @request.session[FormStepsTestController.steps_session_var] = {:first => true, :second => false, :third => nil}
    get :blank
    
    assert_equal :second, @controller.current_step
    assert_equal :second, @controller.next_step # because :second is not succesful
    
    @controller.instance_eval { self.success = true }

    assert_equal :third,  @controller.next_step # because :second is succesful
  end
  
  def test_current_step_and_next_step_with_session_second_true
    @request.session[FormStepsTestController.steps_session_var] = {:first => true, :second => true, :third => nil}
    get :blank
    
    assert_equal :third, @controller.current_step
    assert_equal :third, @controller.next_step # because :third is not succesful
    
    @controller.instance_eval { self.success = true }

    assert_equal nil,    @controller.next_step # because :third is succesful
  end
end

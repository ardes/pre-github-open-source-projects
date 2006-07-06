require File.dirname(__FILE__) + '/test_helper'
require File.dirname(__FILE__) + '/fixtures/ajax_crud_model'

class AjaxCrudModelController < ActionController::Base
  ajax_crud :ajax_crud_model
  self.template_root = File.dirname(__FILE__) + '/views'
  
  def default_params
    {:foo => 'bar'}
  end
end

class AjaxCrudTest < Test::Unit::TestCase
  fixtures :ajax_crud_models
  
  def setup
    @controller = AjaxCrudModelController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
  end
  
  def test_model_count
    assert_equal 3, @controller.model_count
    assert_equal 3, @controller.instance_eval { @model_count }
  end
  
  def test_model_list
    list = [ajax_crud_models(:first), ajax_crud_models(:second), ajax_crud_models(:third)]
    assert_equal list, @controller.model_list
    assert_equal list, @controller.instance_eval { @models }
  end
  
  def test_model_desc
    assert_equal 'ajax crud model: 1', @controller.model_desc(ajax_crud_models(:first))
    @controller.instance_eval { @model = AjaxCrudModel.find_by_name('third') }
    assert_equal 'ajax crud model: 3', @controller.model_desc
  end
  
  def test_class_sanitize_url
    assert_equal({:action => 'fred', :params => {:id => 666, :thing => 'here', :b => 'c'}},
      @controller.class.sanitize_url(:id => 666, :thing => 'here', :action => 'fred', :params => {:b => 'c'}))
  end
  
  def test_internal_url
    assert_equal({:action => 'fred', :params => {:foo => 'bar', :id => 666}}, @controller.internal_url(:action => 'fred', :id => 666))
  end
    
  def test_class_public_id_with_no_args
    assert_equal 'ajax_crud_model', AjaxCrudModelController.public_id
  end
  
  def test_class_public_id_with_action
    assert_equal 'ajax_crud_model_action', AjaxCrudModelController.public_id(:action => 'action')
  end
  
  def test_class_public_id_with_id
    assert_equal 'ajax_crud_model_666', AjaxCrudModelController.public_id(:id => 666)
    assert_equal 'ajax_crud_model_666', AjaxCrudModelController.public_id(:params => {:id => 666})
  end
  
  def test_class_public_is_with_action_and_id
    assert_equal 'ajax_crud_model_666_action', AjaxCrudModelController.public_id(:id => 666, :action => 'action')
    assert_equal 'ajax_crud_model_666_action', AjaxCrudModelController.public_id(:params => {:id => 666}, :action => 'action')
  end
  
  def test_index
    get :index
    assert_response :success
    assert_equal assigns['models'], AjaxCrudModel.find_all
    assert_template 'ajax_crud_model/index'
    
    assert_div(nil, nil, 'loading', :class => 'loading')
    assert_div(nil, nil, 'message', :class => 'message')
    assert_action_link('new', 'edit')
    
    AjaxCrudModel.find_all.each do |m|
      assert_div(m.id, :class => 'actions')
      assert_div(m.id, nil, 'item_main', :class => 'item_main')
      assert_div(m.id, nil, 'item_links', :class => 'item_links')
      assert_action_link(m.id, 'edit')
      assert_action_link(m.id, 'show')
      assert_action_link(m.id, 'destroy')
    end
  end
  
  def test_show
    xhr :get, :show, :id => 1
    assert_response :success
    assert_equal assigns['model'], AjaxCrudModel.find(1)
    assert_template 'ajax_crud_model/open'
    
    assert_rjs :insert_html, :top, 'ajax_crud_model_1'
    
    convert_xhr_body
    assert_div 1, 'show', :class => 'action'
    assert_action_form 1, 'show'
  end
  
  def test_new
    xhr :get, :edit, :id => 'new'
    assert_response :success
    assert_kind_of AjaxCrudModel, assigns['model']
    assert_template 'ajax_crud_model/open'
    
    assert_rjs :insert_html, :top, 'ajax_crud_model_new'
    
    convert_xhr_body
    assert_div 'new', 'edit', :class => 'action'
    assert_action_form 'new', 'edit'
  end
  
private
  # id, action, suffix, attrs..
  def assert_div(*args)
    attributes = args.last.is_a?(Hash) ? args.pop : {}
    attributes[:id] = public_id(*args)
    assert_tag :tag => "div", :attributes => attributes
  end
  
  def assert_action_link(id, action)
    assert_tag :tag => 'a', :attributes => {:id => public_id(id, action, 'open')}
    assert_tag :tag => 'a', :attributes => {:id => public_id(id, action, 'goto')}
  end
    
  def assert_action_form(id, action)
    assert_tag :tag => 'form', :attributes => {:action => url_for(@controller.internal_url(
      :controller => @controller.controller_name, :action => action, :id => id))}
  end
  
  def public_id(*args)
    id     = args.shift
    action = args.shift
    suffix = args.shift
    
    public_id  = @controller.controller_name
    public_id += "_#{id}"     if id
    public_id += "_#{action}" if action
    public_id += "_#{suffix}" if suffix
    
    public_id
  end
  
  def convert_xhr_body
    @response.body.gsub!('\"', '"')
  end  
end


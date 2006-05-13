require File.dirname(__FILE__) + '/test_helper'

class InheritViewsController < ActionController::Base
  inherit_views :first, :second
  self.template_root = File.dirname(__FILE__) + '/views'
  
  def default; end
    
  def first; end
    
  def second; end
  
  def in_all; end
    
  def in_first_and_second; end
    
  def in_none; end
end

class InheritViewsTest < Test::Unit::TestCase

  def setup
    @controller = InheritViewsController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
  end
  
  def test_additional_view_paths_array
    assert_equal [:first, :second], @controller.inherit_views_from
  end
  
  def test_action_exists_in_default_views
    get :default
    assert_response :success
  end
  
  def test_action_exists_in_first_views
    get :first
    assert_response :success
  end
  
  def test_action_exists_in_second_views
    get :second
    assert_response :success
  end
  
  def test_view_is_fetched_from_default_if_it_exists
    get :in_all
    assert_tag :tag => 'default'
  end
  
  def test_view_is_fetched_from_first_if_it_exists
    get :in_first_and_second
    assert_tag :tag => 'first'
  end
  
  def test_view_is_not_there
    get :in_none
    assert_response :error
  end
end

  
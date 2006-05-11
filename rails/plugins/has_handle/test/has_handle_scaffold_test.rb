require File.dirname(__FILE__) + '/test_helper'
require File.dirname(__FILE__) + '/test_has_handle_model.rb'

class HasHandleScaffoldController < ActionController::Base
  scaffold :test_has_handle_model
end

class HasHandleScaffoldTest < Test::Unit::TestCase
  fixtures :test_has_handle_models
  
  def setup
    @controller = HasHandleScaffoldController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
  end

  def test_should_have_links_with_handle_on_index
    get :index
    assert_tag :tag => 'a', :attributes => {:href => /\/show\/first/}
    assert_tag :tag => 'a', :attributes => {:href => /\/edit\/first/}
    assert_tag :tag => 'a', :attributes => {:href => /\/show\/second/}
    assert_tag :tag => 'a', :attributes => {:href => /\/edit\/second/}
  end
    
  def test_should_show_first_with_handle_as_id
    get :show, {:id => 'first'}
    assert_response :success
  end
  
  def test_should_edit_first_with_handle_as_id
    get :edit, {:id => 'first'}
    assert_response :success
  end
  
  def test_should_show_first_with_id_as_id
    get :show, {:id => '1'}
    assert_response :success
  end
  
  def test_should_edit_first_with_id_as_id
    get :edit, {:id => '2'}
    assert_response :success
  end
  
  def test_should_preserve_original_handle_in_param_when_updated_with_invalid_handle
    post :update, {:id => '1', :test_has_handle_model => {:handle => 'mal for med'}}
    assert_tag :tag => 'div', :attributes => {:class => 'errorExplanation'} # error
    assert_tag :tag => 'input', :attributes => {:value => 'mal for med'} # malformed handle field
    assert_tag :tag => 'a', :attributes => {:href => /\/show\/first/} # preserved handle in to_param
  end
end
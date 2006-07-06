require 'ardes/ajax_crud/controller'
ActionController::Base.class_eval { extend Ardes::AjaxCrud::Controller }

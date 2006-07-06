require 'ardes/ajax_crud_belongs_to/controller'
ActionController::Base.class_eval { extend Ardes::AjaxCrudBelongsTo::Controller }
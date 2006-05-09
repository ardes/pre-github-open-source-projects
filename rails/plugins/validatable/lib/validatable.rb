# Include ActiveRecord::Validations in your class, for example:
#
#   class MyObj
#     include Validatable
#     attr_accessor :name, :age
#     validates_presence_of :age
#     validates_format_of :name, :with => /bugs bunny/
#   end
#
#   # calls to my_obj.valid? will perform validations on instance variables
#
# NOTE: if you use method_missing you should define that method *before* including Validatable
#
# WARNING: this code depends on the internals of ActiveRecord::Validations, not
# an api.  So test often if you use this. (Or push the core team to refactor the
# Validations stuff out of active record!)
#
# The following methods (and more) won't work as expected without ActiveRecord
# so you may wish to alias them away:
#   validates_uniqueness_of, create!, validate_on_create, validate_on_update, save_with_validation
#
module Validatable
  def self.included(base)
    base.class_eval do
      # append features to including class
      extend ClassMethods
      alias_method_chain :method_missing, :validatable
      
      # We don't know if we have methods that Validations alias_method_chains
      # so define them to raise NotImplementedError if we don't have them
      ([:save, :update_attribute, :save!] - self.instance_methods).each do |method|
        define_method(method) { raise NotImplementedError }
      end
      include ActiveRecord::Validations
    end
  end

  def [](key)
    instance_variable_get("@#{key}")
  end

  def method_missing_with_validatable(method_id, *args)
    if md = /_before_type_cast$/.match(method_id.to_s)
      attr_name = md.pre_match
      return self[attr_name] if self.respond_to?(attr_name)
    end
    method_missing_without_validatable(method_id, *args)
  end

protected 
  def new_record?
    true
  end
  
  module ClassMethods
    def human_attribute_name(attribute_key_name)
      attribute_key_name.humanize
    end
  end
end
module Ardes
  # include ActiveRecord::Validations in your class
  module Validatable
    def self.included(base)
      base.class_eval do
        class <<self
          def not_implemented; raise NotImplementedError; end
        end
        def not_implemented; self.class.not_implemented; end
        
        # these methods must be defined before include
        alias_method :save,             :not_implemented
        alias_method :update_attribute, :not_implemented
        alias_method :save!,            :not_implemented
        
        include ::ActiveRecord::Validations
        
        # these methods must be defined after include
        #alias_method :save!,            :not_implemented
        
        class <<self
          alias_method :validates_uniqueness_of,  :not_implemented
          alias_method :create!,                  :not_implemented
          alias_method :validate_on_create,       :not_implemented
          alias_method :validate_on_update,       :not_implemented
          alias_method :save_with_validation,     :not_implemented
        end
      end
    end

    def [](key)
      instance_variable_get("@#{key}")
    end

    def method_missing( method_id, *args )
      if md = /_before_type_cast$/.match(method_id.to_s)
        attr_name = md.pre_match
        return self[attr_name] if self.respond_to?(attr_name)
      end
      super
    end

  protected 
    def self.human_attribute_name(attribute_key_name)
      attribute_key_name.humanize
    end

    def new_record?
      true
    end
  end
end
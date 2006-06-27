module Ardes
  module HasAssociated
    def self.included(base)
      base.class_eval { alias_method_chain :method_missing, :has_associated }
    end
    
    # provide has_xxx? support
    # if the model has a many association i.e.
    #   has_many :things
    # then you can call obj.has_thing?(thing_obj) or obj.has_thing?(thing_id)
    # second argument forces a reload, e.g. obj.has_thing?(thinig_id, true)
    #
    def method_missing_with_has_associated(method_id, *arguments)
      if match = /has_([_a-zA-Z]*)\?/.match(method_id.to_s)
        assoc = match[1].pluralize.to_sym
        if self.class.reflect_on_association(assoc)
          reload = arguments.last || false
          assoc_ids = send(assoc, reload).collect {|obj| obj.send(obj.class.primary_key)}
          id = arguments.first.is_a?(::ActiveRecord::Base) ? arguments.first.send(arguments.first.class.primary_key) : arguments.first
          return assoc_ids.include?(id)
        end
      end
      method_missing_without_has_associated(method_id, *arguments)
    end
  end
end
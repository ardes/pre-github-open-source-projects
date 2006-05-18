module Ardes
  module ActiveRecord
    module AggregationsAllowNil
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods 
        def composed_of(part_id, options = {})
          options.assert_valid_keys(:class_name, :mapping, :allow_nil)

          name        = part_id.id2name
          class_name  = options[:class_name] || name.camelize
          mapping     = options[:mapping] || [ name, name ]
          allow_nil   = options[:allow_nil] || false

          reader_method(name, class_name, mapping, allow_nil)
          writer_method(name, class_name, mapping, allow_nil)
      
          create_reflection(:composed_of, part_id, options, self)
        end
    
      private
        def reader_method(name, class_name, mapping, allow_nil)
          mapping = (Array === mapping.first ? mapping : [ mapping ])
          if allow_nil
            allow_nil_condition = mapping.collect{|pair| "!read_attribute(\"#{pair.first}\").nil?"}.join(" && ")
          else
            allow_nil_condition = "true"
          end
          module_eval <<-end_eval
            def #{name}(force_reload = false)
              if (@#{name}.nil? || force_reload) && #{allow_nil_condition}
                @#{name} = #{class_name}.new(#{mapping.collect{ |pair| "read_attribute(\"#{pair.first}\")"}.join(", ")})
              end
              return @#{name}
            end
          end_eval
        end        
  
        def writer_method(name, class_name, mapping, allow_nil)
          mapping = (Array === mapping.first ? mapping : [ mapping ])
          if allow_nil
            module_eval <<-end_eval
              def #{name}=(part)
                if part.nil?
                  #{mapping.collect{ |pair| "@attributes[\"#{pair.first}\"] = nil" }.join("\n")}
                else
                  @#{name} = part.freeze
                  #{mapping.collect{ |pair| "@attributes[\"#{pair.first}\"] = part.#{pair.last}" }.join("\n")}
                end
              end
            end_eval
          else
            module_eval <<-end_eval
              def #{name}=(part)
                @#{name} = part.freeze
                #{mapping.collect{ |pair| "@attributes[\"#{pair.first}\"] = part.#{pair.last}" }.join("\n")}
              end
            end_eval
          end
        end
      end
    end
  end
end
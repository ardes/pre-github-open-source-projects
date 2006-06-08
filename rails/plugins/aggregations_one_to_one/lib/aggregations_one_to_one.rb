module ActiveRecord
  module Aggregations
    module ClassMethods
      def writer_method(name, class_name, mapping, allow_nil)
        mapping = (Array === mapping.first ? mapping : [ mapping ])
  
        if allow_nil
          module_eval <<-end_eval
            def #{name}=(part)
              if part.nil?
                #{mapping.collect { |pair| "@attributes[\"#{pair.first}\"] = nil" }.join("\n")}
              else
                #{mapping.size == 1 ? "part = #{class_name}.new(part) unless part.is_a? #{class_name}" : ""}
                @#{name} = part.freeze
                #{mapping.collect { |pair| "@attributes[\"#{pair.first}\"] = part.#{pair.last}" }.join("\n")}
              end
            end
          end_eval
        else
          module_eval <<-end_eval
            def #{name}=(part)
              #{mapping.size == 1 ? "part = #{class_name}.new(part) unless part.nil? or part.is_a? #{class_name}" : ""}
              @#{name} = part.freeze
              #{mapping.collect{ |pair| "@attributes[\"#{pair.first}\"] = part.#{pair.last}" }.join("\n")}
            end
          end_eval
        end
      end
    end
  end
end

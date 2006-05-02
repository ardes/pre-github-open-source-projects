module Ardes# :nodoc:
  module ActiveRecord# :nodoc:
    module Has# :nodoc:
      #
      # Specify this to have a unique handle associated with the model
      #
      # This will
      #   - add a validation for the handle
      #   - allow calls like find(:some_handle) and find([:some_handle, :other_handle])
      module Handle
        def self.included(base)
          base.extend(ClassMethods)
        end

        module ClassMethods
          def has_handle(column = :handle)
            include ActMethods
            self.class_eval do
              cattr_accessor :handle_column
              self.handle_column = column.to_s
              validates_handle self.handle_column
            end
          end
          
          def validates_handle(*attributes)
            attributes = [:handle] if attributes.empty?
            attributes.each do |a|
              validates_presence_of a
              validates_uniqueness_of a
              validates_length_of a, :maximum => 64
              validates_format_of a, :with => /^[a-z_][0-9a-z_]*$/,
                :message => "must contain only lowercase letters, numbers, and underscore"
            end
          end
        end
        
        module ActMethods
          def self.included(base)
            base.class_eval do
              class <<self
                include ClassMethods
                alias_method :find_one_without_handle, :find_one
                alias_method :find_one, :find_one_with_handle
                alias_method :find_some_without_handle, :find_some
                alias_method :find_some, :find_some_with_handle
              end
            end
          end

          module ClassMethods
          private
            def id_is_handle?(id)
              id.is_a? String and not id =~ /^\d*$/
            end
            
            def find_one_with_handle(id, options)
              if id_is_handle?(id)
                conditions = " AND (#{sanitize_sql(options[:conditions])})" if options[:conditions]
                options.update :conditions => "#{table_name}.#{handle_column} = #{quote(id,columns_hash[handle_column])}#{conditions}"

                if result = find_initial(options)
                  result
                else
                  raise ::ActiveRecord::RecordNotFound, "Couldn't find #{name} with #{handle_column.upcase}=#{id}#{conditions}"
                end
              else
                find_one_without_handle(id, options)
              end
            end

            def find_some_with_handle(ids, options)
              if id_is_handle?(ids.first)
                conditions = " AND (#{sanitize_sql(options[:conditions])})" if options[:conditions]
                ids_list   = ids.map { |id| quote(id,columns_hash[handle_column]) }.join(',')
                options.update :conditions => "#{table_name}.#{handle_column} IN (#{ids_list})#{conditions}"

                result = find_every(options)

                if result.size == ids.size
                  result
                else
                  raise ::ActiveRecord::RecordNotFound, "Couldn't find all #{name.pluralize} with #{handle_column.upcase}s (#{ids_list})#{conditions}"
                end
              else
                find_some_without_handle(ids, options)
              end
            end
          end
        end
      end
    end
  end
end

ActiveRecord::Base.class_eval { include Ardes::ActiveRecord::Has::Handle }


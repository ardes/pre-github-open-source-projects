module ActiveRecord# :nodoc:
  module Has# :nodoc:
    #
    # Specify this to have a unique handle associated with the model
    #
    # This is like an id in that it can be used to uniquely find a record, but
    # it is not immutable (it can be changed), and can also be used as a 
    # descriptor in many situations.
    #
    # This will
    #   - add a validation for the handle
    #   - allow calls like find('some_handle') and find(['some_handle', 'other_handle'])
    #   - works with scaffolding out of the box for more informative urls (people/fred_jones)
    # 
    # Example of use:
    #   class MyObject < ActiveRecord::Base
    #     has_handle
    #   end
    #
    #   class MyObject < ActiveRecord::Base
    #     has_handle :name_of_entity
    #   end
    #
    #   class MyObject < ActiveRecord::Base
    #     has_handle :validate => false
    #   end
    #
    module Handle
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def has_handle(*args)
          options = args.last.is_a?(Hash) ? args.pop : {}
          column  = (args.pop or :handle)
          self.class_eval do
            cattr_accessor :handle_column
            self.handle_column = column.to_s
            validates_handle self.handle_column unless options[:validate] == false
          end
          include ActMethods
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
              alias_method_chain :find_one, :handle
              alias_method_chain :find_some, :handle
            end
            alias_method_chain :initialize, :handle
            after_save :cache_handle
          end
        end
        
        def initialize_with_handle(*args)
          result = initialize_without_handle(*args)
          cache_handle unless new_record?
          result
        end

        def cache_handle
          @handle = send(self.handle_column)
        end

        def to_param
          @handle
          #unless new_record?
          #  @handle or @handle = self.connection.select_value(
          #    "SELECT #{self.handle_colum} FROM #{self.class.table_name} " +
          #    "WHERE #{self.class.primary_key} = #{send(self.class.priumary_key)}")
          #end
        end
                
        module ClassMethods
          def id_is_handle?(id)
            id.is_a? String and not id =~ /^\d*$/
          end
          
          def find_with_handle(*args)
            if result = find_without_handle(*args)
              if result.respond_to? :each 
                result.each {|r| r.cache_handle}
              elsif result.is_a? self
                result.cache_handle
              end
            end
            result
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

ActiveRecord::Base.class_eval { include ActiveRecord::Has::Handle }
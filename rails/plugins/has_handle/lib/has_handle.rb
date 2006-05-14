module ActiveRecord::Has# :nodoc:
  #
  # Specify this to have a unique handle associated with the model
  #
  # This is like an id in that it can be used to uniquely find a record, but
  # it is not immutable (it can be changed), and can also be used as a 
  # descriptor in many situations.
  #
  # This will
  #   - add a validation for the handle
  #   - allow calls like exists('some handle'), find('some_handle') and find(['some_handle', 'other_handle'])
  #   - works with controllers (and scaffolding) out of the box for more informative urls (people/fred_jones)
  #     because a handle may be in flux (an id can't) the authoritatve handle is cached.  A
  #     call to 'to_param' will reveal the authoritative handle (the record in the db's handle)
  # 
  # Example of use:
  #   class MyObject < ActiveRecord::Base
  #     has_handle
  #   end
  #
  #   class MyObject < ActiveRecord::Base
  #     has_handle :name_of_handle_column
  #   end
  #
  #   class MyObject < ActiveRecord::Base
  #     has_handle :validate => false   # if you want to provide custom validation
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
          include ActMethods
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
            alias_method_chain :find_one, :handle
            alias_method_chain :find_some, :handle
            alias_method_chain :instantiate, :handle
            alias_method_chain :exists?, :handle?
          end
          after_save :cache_handle
        end
      end
      
      def cache_handle
        @handle = send(self.handle_column)
      end

      def to_param
        @handle
      end
              
      module ClassMethods
        def id_is_handle?(id)
          id.is_a? String and not id =~ /^\d*$/
        end
        
        def instantiate_with_handle(*args)
          result = instantiate_without_handle(*args)
          result.cache_handle
          result
        end
        
        def find_one_with_handle(id, options)
          return find_one_without_handle(id, options) unless id_is_handle?(id)
          
          conditions = " AND (#{sanitize_sql(options[:conditions])})" if options[:conditions]
          options.update :conditions => "#{table_name}.#{handle_column} = #{quote(id,columns_hash[handle_column])}#{conditions}"

          if result = find_initial(options)
            result
          else
            raise ::ActiveRecord::RecordNotFound, "Couldn't find #{name} with #{handle_column.upcase}=#{id}#{conditions}"
          end
        end

        def find_some_with_handle(ids, options)
          return find_some_without_handle(ids, options) unless id_is_handle?(ids.first)
          
          conditions = " AND (#{sanitize_sql(options[:conditions])})" if options[:conditions]
          ids_list   = ids.map { |id| quote(id,columns_hash[handle_column]) }.join(',')
          options.update :conditions => "#{table_name}.#{handle_column} IN (#{ids_list})#{conditions}"

          result = find_every(options)
          if result.size == ids.size
            result
          else
            raise ::ActiveRecord::RecordNotFound, "Couldn't find all #{name.pluralize} with #{handle_column.upcase}s (#{ids_list})#{conditions}"
          end
        end
        
        def exists_with_handle?(id)
          return exists_without_handle?(id) unless id_is_handle?(id)
          !find(:first, :conditions => ["#{handle_column} = ?", id]).nil? rescue false
        end
      end
    end
  end
end

ActiveRecord::Base.class_eval { include ActiveRecord::Has::Handle }
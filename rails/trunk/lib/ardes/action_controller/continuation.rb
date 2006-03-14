module Ardes
  module ActionController
    module Continuation
      
      CONTINUTAION_HANDLER_SESSION_VAR = '__continuation_handler'
      
      def self.included(base)
        super
        base.extend(ClassMethods)
      end

      module ClassMethods
        def has_continuations(options = {})
          include InstanceMethods
          self.class_eval do
            cattr_accessor :continuation_session_vars
            self.continuation_session_vars = (options[:session] or [])
          end
        end
      end
      
      module InstanceMethods
        def self.included(base)
          super
          base.send :alias_method, :perform_action_without_continuations, :perform_action
          base.send :alias_method, :perform_action, :perform_action_with_continuations
        end

        def perform_action_with_continuations
          continuation_initialize
          page = catch :continuation_dispatch do
            return perform_action_without_continuations
          end
          # If we're here it means a :continuation_dispatch was thrown.
          # If we're dispatching to an action in this controller, then
          # pass control to it, otherwise redirect to the named controller
          if page.url_options[:controller] == controller_name
            params.merge(page.url_options[:params])
            self.action_name = page.url_options[:action]
            return perform_action
          else
            redirect_to page.url_options
          end
        end

      private
        def continuation_initialize
          session[CONTINUTAION_HANDLER_SESSION_VAR] = Handler.new unless session[CONTINUTAION_HANDLER_SESSION_VAR]
          @continuation_handler = session[CONTINUTAION_HANDLER_SESSION_VAR]
          @continuation_handler.set_current(self)
          @continuation_handler.pop(self)
        end

        def continuation_call(options)
          @continuation_handler.call(Page.new(options, self), self)
        end

        def continuation_return(result, target = nil)
          if target.is_a? Hash
            target = Page.new(target, self)
          elsif target.nil?
            target = Page.current(self)
          end
          @continuation_handler.return_result(result, target)
        end

        def continuation_return_page
          target = Page.current(self)
          @continuation_handler.check_target_is_top(target)
          target
        end
        
        def continuation_cleanup(to_clean = nil)
          @continuation_handler.cleanup(to_clean)
        end
      end

      class Handler
        attr_accessor :states, :results, :current
          
        def initialize
          @states = Array.new
          @results = Hash.new
        end

        def set_current(controller)
          @current = Page.current(controller)
        end

        def call(target, controller)
          catch :no_result do
            return result_for(target)
          end
          @states.push(State.new(@current, target, controller))
          throw :continuation_dispatch, target
        end

        def return_result(result, target)
          if check_target_is_top(target)
            @states.last.result = result
            throw :continuation_dispatch, @states.last.source
          end
        end

        def pop(controller)
          if @states.last and @states.last.source.id == @current.id
            # check if we have a result, if not, dispatch to the target
            unless @states.last.has_result?
              throw :continuation_dispatch, @states.last.target
            end
            state = @states.pop
            # restore state to controller, and save result
            controller.params = state.params
            state.session.each {|k,v| controller.session[k] = v }
            @results[state.source.id] = Hash.new unless @results[state.source.id]
            @results[state.source.id][state.target.id] = state.result
          end
        end

        def check_target_is_top(target)
          if target.id == @states.last.target.id
            true
          else
            throw :continuation_dispatch, @states.last.target
          end
        end

        def result_for(target)
          if @results.key?(@current.id) and @results[@current.id].key?(target.id)
            return @results[@current.id][target.id]
          else
            throw :no_result
          end
        end

        def cleanup(to_clean = nil)
          if to_clean == :all
            @results = Hash.new
            @states = Array.new
          else
            to_clean = @current if to_clean.nil?
            @results.delete(to_clean.id)
            @states.delete_if {|s| s.source.id == to_clean.id}
          end
        end
      end

      class State
        attr_reader :result, :source, :target, :params, :session
        
        def result=(result)
          @has_result = true
          @result = result
        end
        
        def has_result?
          @has_result
        end
        
        def initialize(source, target, controller)
          @source = source
          @target = target
          @params = controller.params.clone
          @session = Hash.new
          controller.continuation_session_vars.each do |v|
            @session[v] = controller.session[v]
          end
        end
      end    

      class Page
        attr_reader :id

        def self.current(controller)
          params = HashWithIndifferentAccess.new
          params.merge!(controller.request.query_parameters)
          params.merge!(controller.request.path_parameters)
          Page.new({:params => params}, controller)
        end

        def initialize(options, controller)
          @params = options[:params] ? options[:params].clone : HashWithIndifferentAccess.new
          @params.delete('action')
          @params.delete('controller')
          @controller = (options[:controller] or controller.controller_name)
          @action =     (options[:action] or controller.action_name)
          @id = create_id
        end

        def create_id
          @controller + ':' + @action + (@params.size > 0 ? ':' + @params.to_json : '')
        end

        def url_options
          {:controller => @controller, :action => @action, :params => @params}
        end
      end
    end
  end
end

ActionController::Base.class_eval { include Ardes::ActionController::Continuation }
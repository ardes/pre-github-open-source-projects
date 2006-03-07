module Ardes
  module ActionController
    module Continuation
      
      def self.included(base)
        super
        base.extend(ClassMethods)
      end

      module ClassMethods
        def has_continuations
          include InstanceMethods
        end
      end
      
      module InstanceMethods
        def self.included(base)
          base.send :alias_method, :perform_action_without_continuations, :perform_action
          base.send :alias_method, :perform_action, :perform_action_with_continuations
        end

      public
        def perform_action_with_continuations
          continuation_initialize
          page = catch :continuation_dispatch do
            return perform_action_without_continuations
          end
          redirect_to page.redirect_options
        end

      private
        def continuation_initialize
          session['__continuation_handler'] = Handler.new unless session['__continuation_handler']
          @continuation_handler = session['__continuation_handler']
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
        attr_reader :result, :source, :target, :params
        
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
          @params = controller.params
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
          @action + ':' + @controller + (@params.size > 0 ? ':' + @params.to_json : '')
        end

        def redirect_options()
          {:controller => @controller, :action => @action, :params => @params}
        end
      end
    end
  end
end

ActionController::Base.class_eval { include Ardes::ActionController::Continuation }
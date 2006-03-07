module Ardes
  module ActionController
    module Continuation
      
      def self.included(base)
        super
        base.extend(ClassMethods)
      end

      module ClassMethods
        def has_continuations
          before_filter :continuation_initialize
          include InstanceMethods
        end
      end
      
      module InstanceMethods       
      private
        def continuation_initialize
          session[:continuation_handler] = Handler.new unless session[:continuation_handler]
          @continuations = session[:continuation_handler]
          @continuations.set_current(self)
        end

        def continuation_dispatcher
          result = catch :continuation_dispatch do
            yield
          end
          if result.is_a? Page
            redirect_to result.redirect_options
          end
        end
        
        def continuation
          continuation_dispatcher do
            @continuations.pop
            yield
            @continuations.cleanup
          end
        end
        
        def continuation_call(options)
          @continuations.call(Page.new(options, self))
        end
        
        def continuation_return(result, target = nil)
          if target.is_a? Hash
            target = Page.new(target, self)
          elsif target.nil?
            target = Page.current(self)
          end
          continuation_dispatcher do
            @continuations.return_result(result, target)
          end
        end
        
        def continuation_return_page
          target = Page.current(self)
          continuation_dispatcher do
            @continuations.check_target_is_top(target)
          end
          target
        end
      end
      
      class Handler
        attr_accessor :states, :results, :current
          
        def initialize()
          @states = Array.new
          @results = Hash.new
        end

        def set_current(controller)
          @current = Page.current(controller)
        end
        
        def call(target)
          catch :no_result do
            return result_for(target)
          end
          @states.push(State.new(@current, target))
          throw :continuation_dispatch, target
        end
        
        def return_result(result, target)
          if check_target_is_top(target)
            @states.last.result = result
            throw :continuation_dispatch, @states.last.source
          end
        end
        
        def pop
          if @states.last and @states.last.source.id == @current.id
            # check if we have a result, if not, dispatch to the target
            unless @states.last.has_result?
              throw :continuation_dispatch, @states.last.target
            end
            save_result(@states.pop)
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
    
        def save_result(state)
          @results[state.source.id] = Hash.new unless @results[state.source.id]
          @results[state.source.id][state.target.id] = state.result
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
        attr_reader :result, :source, :target
        
        def result=(result)
          @has_result = true
          @result = result
        end
        
        def has_result?
          @has_result
        end
        
        def initialize(source, target)
          @source = source
          @target = target
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
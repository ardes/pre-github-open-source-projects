module Ardes
  module FormSteps
    def self.included(base) # :nodoc:
      super
      base.extend(ClassMethods)
    end
    
    module ClassMethods
      #
      # specifiying form_steps :step1, :step2 gives support for multi-step forms
      # 
      # this sets a session var "#{controller_name}_form_steps" = Hash
      # the hash keys are the step symbols and the values are
      #   nil   - the step has not been processed
      #   true  - the step has been processed and succeeded
      #   false - the step has been processed and did not succeed
      #
      # in your controller specify these methods for each step
      # protected
      #   process_#{step} - called before step is processed (optional)
      #     within this method:
      #       self.success = true/false (if not called success is assumed true)
      #       
      #       if self.success is true, the next step is prepared and rendered
      #       if self.success is false, the current step is re-rendered (without prepare)
      #
      #       you can specify the next step by calling self.next_step = (step) in your method
      #       if you don't specify this then the next step is calculated.
      # 
      #   display_#{step} - called before a step is displayed (optional)
      #
      def form_steps(*steps)
        options = steps.last.is_a?(Hash) ? steps.pop : {}
        
        include InstanceMethods
        
        cattr_accessor :steps, :session_var_name, :on_complete_redirect_to
        self.steps                   = steps
        self.session_var_name        = "#{controller_name}_form_steps"
        self.on_complete_redirect_to = options[:on_complete_redirect_to]
        
        before_filter :initialize_session
        
        hide_action :success, :current_step, :next_step
      end

      module InstanceMethods
        # goto named step (or current step) (use this to 'link to' a step)
        def step
          display_step
        end
        alias_method :index, :step
      
        # process step (use this to process a step)
        def process_step
          raise 'step not specified' unless params[:step]
          
          send("process_#{current_step}") if respond_to?("process_#{current_step}")
          
          self.success = true if success == nil # we assume success if it's not specified in process
        
          if success
            if next_step
              display_step(next_step)
            else
              steps_complete
            end
          else
            render_step
          end
        end
        
        # if @current_step is set then return that,
        # otherwise return params[:step] if it is set,
        # otherwise return first step that's unsuccessful,
        # lastly return the last step.
        # Calling this locks the current step (unlock it by self.current_step = nil)
        def current_step
          @current_step or @current_step = ((params[:step].to_sym rescue nil) or first_unsuccessful_step or self.steps.last)
        end
        
        # if @next_step is set then return that
        # otherwise return params[:next_step] if it is set,
        # otherwise return first step that's unsuccessful.
        # if there is no next step return nil
        def next_step
          @next_step or (params[:next_step].to_sym rescue nil) or first_unsuccessful_step or nil
        end
         
        # returns true/false/nil meaning successful/unseccessful/not processed
        def success(step = self.current_step)
          session[self.session_var_name][step]
        end
      
      protected
        # override this to provide your own completion code
        def steps_complete
          if self.on_complete_redirect_to
            respond_to do |wants|
              type.html { redirect_to self.on_complete_redirect_to }
              type.js   { page.redirect_to self.on_complete_redirect_to }
            end
          else
            render_step(self.steps.last)
          end
        end
    
        def display_step(step = self.current_step)
          send("display_#{step}") if respond_to?("display_#{step}")
          render_step(step)
        end

        # default rendering is to render a template named as step (.rhtml or .rjs)
        # override this to provide your own rendering scheme
        def render_step(step = self.current_step)
          respond_to do |wants|
            wants.html { render :action => step }
            wants.js   { render :action => step }
          end
        end      

        # set the session var if it's not already set
        def initialize_session
          session[self.session_var_name] ||= self.steps.inject({}) {|n, i| n.merge({i => nil})}
        end

      private
        def first_unsuccessful_step
          self.steps.each do |step|
             return step unless success(step)
          end
          nil
        end
        
        # sets success of current step
        def success=(value)
          set_success(self.current_step, value)
        end
      
        # sets success of a particular step
        def set_success(step, value)
          session[self.session_var_name][step] = value
        end
      
        # sets the current step (only necessay if you're departing from the default step order)
        def current_step=(step)
          @current_step = step
        end
      
        # sets the next step (only necessay if you're departing from the default step order)
        def next_step=(step)
          @next_step = step
        end
      end
    end
  end
end
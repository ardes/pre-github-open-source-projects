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
      # you can set these by set_success(:step, val)
      #
      #
      # in your controller specify these methods for each step
      # protected
      #   #{step} - called before step is processed (optional)
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
      #   In both of the above methods, you may render a response.  If none is rendered
      #   then render_step will render the response
      #
      def form_steps(*steps)
        options = steps.last.is_a?(Hash) ? steps.pop : {}
        
        include InstanceMethods
        
        cattr_accessor :steps, :steps_session_var, :on_complete_redirect_to
        self.steps                   = steps
        self.steps_session_var       = "#{controller_name}_form_steps".to_sym
        self.on_complete_redirect_to = options[:on_complete_redirect_to]
        
        before_filter { |controller| controller.session[self.steps_session_var] ||= {} }
        
        hide_action :success, :current_step, :next_step
      end

      module InstanceMethods
        # goto named step (or current step) (use this to 'link to' a step)
        def step
          prepare_and_display_step
        end
        alias_method :index, :step
      
        # process step (use this to process a step)
        def process_step
          raise ::ActionController::UnknownAction unless params[:step] and self.steps.include?(current_step)
          
          send(current_step) if respond_to?(current_step)
          
          self.success = true if success == nil # we assume success if it's not specified in process
        
          if success
            if next_step
              prepare_and_display_step(next_step)
            else
              steps_complete
            end
          else
            display_step unless performed?
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
          session[self.steps_session_var][step]
        end
      
      protected
        # override this to provide your own completion code
        def steps_complete
          if self.on_complete_redirect_to
            respond_to do |wants|
              wants.html { redirect_to self.on_complete_redirect_to }
              wants.js do
                @redirect_to = self.on_complete_redirect_to
                render(:update) {|page| page.redirect_to @redirect_to }
              end
            end
          else
            prepare_and_display_step(self.steps.last)
          end
        end
    
        def prepare_and_display_step(step = self.current_step)
          raise ::ActionController::UnknownAction unless self.steps.include?(step)
          send("display_#{step}") if respond_to?("display_#{step}") and self.steps.include?(step)
          display_step(step) unless performed?
        end

        def display_step(step = self.current_step)
          set_view_attributes(step)
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

        # set some variables so the template knows the state of the steps
        def set_view_attributes(step)
          @steps     = session[self.steps_session_var]
          @step      = step
          @next_step = next_step
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
          session[self.steps_session_var][step] = value
        end
        
        # resets success states for all steps to 'untried'
        def reset_success
          session[self.steps_session_var] = {}
        end
      
        # sets the current step (only necessay if you're departing from the default step order)
        # or providing an action that is not called by process_step.
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
module Ardes
  module Test
    module FormStepsIntegrationSession
      def processes_step(step, params = {})
        params[:step] = step
        xpost url_for(:controller => controller.controller_name, :action => 'process_step', :step => step), stringify_params(params)
        assert_response :success
        assert_xtemplate "#{controller.controller_name}/step.rhtml", "#{controller.controller_name}/step.rjs"
      end
  
      def goes_to_step(step, params = {})
        xget url_for(:controller => controller.controller_name, :action => 'step', :step => step), stringify_params(params)
        assert_response :success
        assert_xtemplate "#{controller.controller_name}/step.rhtml", "#{controller.controller_name}/step.rjs"
      end
  
      def assert_at_step(step, body_contains = nil)
        assigned_step = controller.instance_eval '@step'
        assert(assigned_step == step, "Expected step <#{step.inspect}>, but got <#{assigned_step.inspect}>")
        assert_body_contains(body_contains) if body_contains
      end
    end
  end
end
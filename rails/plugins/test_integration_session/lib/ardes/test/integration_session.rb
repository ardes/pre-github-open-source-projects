module Ardes
  module Test
    module IntegrationSession
  
      attr_accessor :js
  
      def xget(*args)
        if js
          old_accept = self.accept
          self.accept = 'text/javascript'
          result = xml_http_request(*args)
          self.accept = old_accept
          result
        else
          self.accept = ''
          get(*args)
        end
      end
  
      def xpost(*args)
        if js
          old_accept = self.accept
          self.accept = 'text/javascript'
          result = xml_http_request(*args)
          self.accept = old_accept
          result
        else
          post(*args)
        end
      end
  
      def assert_xtemplate(template, xtemplate)
        js ? assert_template(xtemplate) : assert_template(template)
      end
      
      def assert_body_contains(contains)
        contains.gsub!('"', '\"') if js
        assert(response.body =~ Regexp.new(Regexp.escape(contains)), "Expected '#{contains}' not found in body")
      end
      
      def stringify_params(params)
        stringified = {}
        params.each do |k,v|
          if v.is_a?(Hash)
            stringified[k.to_s] = stringify_params(v)
          else
            stringified[k.to_s] = v.to_s
          end
        end
        stringified
      end   
    end
  end
end
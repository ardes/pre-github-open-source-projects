module Ardes
  module ActiveRecord
    module Defaults
      def load_defaults!
        defaults_file = "#{RAILS_ROOT}/data/defaults/" + self.class.name.downcase + '.yml'
        if File::exists? defaults_file
          YAML::load_file(defaults_file).each { |a,v| self[a]=v }
        end
        self
      end
    end
  end
end

ActiveRecord::Base.class_eval { include Ardes::ActiveRecord::Defaults }


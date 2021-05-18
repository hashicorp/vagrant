module Vagrant
  module Config
    module V2
      # This is a configuration object that can have anything done
      # to it. Anything, and it just appears to keep working.
      class DummyConfig
        def method_missing(name, *args, &block)
          DummyConfig.new
        end

        def set_options(options)
          options.each do |key, value|
            var_name = "@#{key.to_s}"
            self.instance_variable_set(var_name, value)
          end
        end

        def instance_variables_hash
          instance_variables.inject({}) do |acc, iv|
            acc[iv.to_s[1..-1]] = instance_variable_get(iv)
            acc
          end
        end
      end
    end
  end
end

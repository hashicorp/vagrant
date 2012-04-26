module Vagrant
  module Config
    class V1
      # Base class for configuration keys. It is not required to inherit
      # from this class but this class provides useful helpers that config
      # classes may wish to use.
      class Base
        # Merge another configuration object into this one. This assumes that
        # the other object is the same class as this one.
        #
        # @param [Object] other The other configuration object to merge from,
        #   this must be the same type of object as this one.
        # @return [Object] The merged object.
        def merge(other)
          result = self.class.new

          # Set all of our instance variables on the new class
          [self, other].each do |obj|
            obj.instance_variables.each do |key|
              # Ignore keys that start with a double underscore. This allows
              # configuration classes to still hold around internal state
              # that isn't propagated.
              if !key.to_s.start_with?("__")
                result.instance_variable_set(key, obj.instance_variable_get(key))
              end
            end
          end

          result
        end

        # Called by {Root} after the configuration is loaded to validate
        # the configuaration objects. Subclasses should implement this
        # method and add any errors to the `errors` object given.
        #
        # @param [ErrorRecorder] errors
        def validate(env, errors); end
      end
    end
  end
end

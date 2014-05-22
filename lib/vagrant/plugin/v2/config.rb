require "set"

module Vagrant
  module Plugin
    module V2
      # This is the base class for a configuration key defined for
      # V2. Any configuration key plugins for V2 should inherit from this
      # class.
      class Config
        # This constant represents an unset value. This is useful so it is
        # possible to know the difference between a configuration value that
        # was never set, and a value that is nil (explicitly). Best practice
        # is to initialize all variables to this value, then the {#merge}
        # method below will "just work" in many cases.
        UNSET_VALUE = Object.new

        # This is called as a last-minute hook that allows the configuration
        # object to finalize itself before it will be put into use. This is
        # a useful place to do some defaults in the case the user didn't
        # configure something or so on.
        #
        # An example of where this sort of thing is used or has been used:
        # the "vm" configuration key uses this to make sure that at least
        # one sub-VM has been defined: the default VM.
        #
        # The configuration object is expected to mutate itself.
        def finalize!
          # Default implementation is to do nothing.
        end

        # Merge another configuration object into this one. This assumes that
        # the other object is the same class as this one. This should not
        # mutate this object, but instead should return a new, merged object.
        #
        # The default implementation will simply iterate over the instance
        # variables and merge them together, with this object overriding
        # any conflicting instance variables of the older object. Instance
        # variables starting with "__" (double underscores) will be ignored.
        # This lets you set some sort of instance-specific state on your
        # configuration keys without them being merged together later.
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
              if !key.to_s.start_with?("@__")
                # Don't set the value if it is the unset value, either.
                value = obj.instance_variable_get(key)
                result.instance_variable_set(key, value) if value != UNSET_VALUE
              end
            end
          end

          # Persist through the set of invalid methods
          this_invalid  = @__invalid_methods || Set.new
          other_invalid = other.instance_variable_get(:"@__invalid_methods") || Set.new
          result.instance_variable_set(:"@__invalid_methods", this_invalid + other_invalid)

          result
        end

        # Capture all bad configuration calls and save them for an error
        # message later during validation.
        def method_missing(name, *args, &block)
          return super if @__finalized

          name = name.to_s
          name = name[0...-1] if name.end_with?("=")

          @__invalid_methods ||= Set.new
          @__invalid_methods.add(name)

          # Return the dummy object so that anything else works
          ::Vagrant::Config::V2::DummyConfig.new
        end

        # Allows setting options from a hash. By default this simply calls
        # the `#{key}=` method on the config class with the value, which is
        # the expected behavior most of the time.
        #
        # This is expected to mutate itself.
        #
        # @param [Hash] options A hash of options to set on this configuration
        #   key.
        def set_options(options)
          options.each do |key, value|
            send("#{key}=", value)
          end
        end

        # Converts this configuration object to JSON.
        def to_json(*a)
          instance_variables_hash.to_json(*a)
        end

        # A default to_s implementation.
        def to_s
          self.class.to_s
        end

        # Returns the instance variables as a hash of key-value pairs.
        def instance_variables_hash
          instance_variables.inject({}) do |acc, iv|
            acc[iv.to_s[1..-1]] = instance_variable_get(iv)
            acc
          end
        end

        # Called after the configuration is finalized and loaded to validate
        # this object.
        #
        # @param [Machine] machine Access to the machine that is being
        #   validated.
        # @return [Hash]
        def validate(machine)
          return { self.to_s => _detected_errors }
        end

        # This returns any automatically detected errors.
        #
        # @return [Array<String>]
        def _detected_errors
          return [] if !@__invalid_methods || @__invalid_methods.empty?
          return [I18n.t("vagrant.config.common.bad_field",
                         fields: @__invalid_methods.to_a.sort.join(", "))]
        end

        # An internal finalize call that no subclass should override.
        def _finalize!
          @__finalized = true
        end
      end
    end
  end
end

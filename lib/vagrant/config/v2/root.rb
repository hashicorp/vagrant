require "set"

require "vagrant/config/v2/util"

module Vagrant
  module Config
    module V2
      # This is the root configuration class. An instance of this is what
      # is passed into version 2 Vagrant configuration blocks.
      class Root
        # Initializes a root object that maps the given keys to specific
        # configuration classes.
        #
        # @param [Hash] config_map Map of key to config class.
        def initialize(config_map, keys=nil)
          @keys              = keys || {}
          @config_map        = config_map
          @missing_key_calls = Set.new
        end

        # We use method_missing as a way to get the configuration that is
        # used for Vagrant and load the proper configuration classes for
        # each.
        def method_missing(name, *args)
          return @keys[name] if @keys.key?(name)

          config_klass = @config_map[name.to_sym]
          if config_klass
            # Instantiate the class and return the instance
            @keys[name] = config_klass.new
            return @keys[name]
          else
            # Record access to a missing key as an error
            @missing_key_calls.add(name.to_s)
            return DummyConfig.new
          end
        end

        # Called to finalize this object just prior to it being used by
        # the Vagrant system. The "!" signifies that this is expected to
        # mutate itself.
        def finalize!
          @config_map.each do |key, klass|
            if !@keys.key?(key)
              @keys[key] = klass.new
            end
          end

          @keys.each do |_key, instance|
            instance.finalize!
            instance._finalize!
          end
        end

        # This validates the configuration and returns a hash of error
        # messages by section. If there are no errors, an empty hash
        # is returned.
        #
        # @param [Environment] env
        # @return [Hash]
        def validate(machine)
          # Go through each of the configuration keys and validate
          errors = {}
          @keys.each do |_key, instance|
            if instance.respond_to?(:validate)
              # Validate this single item, and if we have errors then
              # we merge them into our total errors list.
              result = instance.validate(machine)
              if result && !result.empty?
                errors = Util.merge_errors(errors, result)
              end
            end
          end

          # Go through and delete empty keys
          errors.keys.each do |key|
            errors.delete(key) if errors[key].empty?
          end

          # If we have missing keys, record those as errors
          if !@missing_key_calls.empty?
            errors["Vagrant"] = @missing_key_calls.to_a.sort.map do |key|
              I18n.t("vagrant.config.root.bad_key", key: key)
            end
          end

          errors
        end

        # Returns the internal state of the root object. This is used
        # by outside classes when merging, and shouldn't be called directly.
        # Note the strange method name is to attempt to avoid any name
        # clashes with potential configuration keys.
        def __internal_state
          {
            "config_map"        => @config_map,
            "keys"              => @keys,
            "missing_key_calls" => @missing_key_calls
          }
        end

        # This sets the internal state. This is used by the core to do some
        # merging logic and shouldn't be used by the general public.
        def __set_internal_state(state)
          @config_map        = state["config_map"] if state.key?("config_map")
          @keys              = state["keys"] if state.key?("keys")
          @missing_key_calls = state["missing_key_calls"] if state.key?("missing_key_calls")
        end
      end
    end
  end
end

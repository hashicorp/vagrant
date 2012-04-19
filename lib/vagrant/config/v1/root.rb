module Vagrant
  module Config
    class V1
      # This is the root configuration class. An instance of this is what
      # is passed into version 1 Vagrant configuration blocks.
      class Root
        # Initializes a root object that maps the given keys to specific
        # configuration classes.
        #
        # @param [Hash] config_map Map of key to config class.
        def initialize(config_map, keys=nil)
          @keys       = keys || {}
          @config_map = config_map
        end

        # We use method_missing as a way to get the configuration that is
        # used for Vagrant and load the proper configuration classes for
        # each.
        def method_missing(name, *args)
          return @keys[name] if @keys.has_key?(name)

          config_klass = @config_map[name.to_sym]
          if config_klass
            # Instantiate the class and return the instance
            @keys[name] = config_klass.new
            return @keys[name]
          else
            # Super it up to probably raise a NoMethodError
            super
          end
        end

        # Validates the configuration classes of this instance and raises an
        # exception if they are invalid. If you are implementing a custom configuration
        # class, the method you want to implement is {Base#validate}. This is
        # the method that checks all the validation, not one which defines
        # validation rules.
        def validate!(env)
          # Validate each of the configured classes and store the results into
          # a hash.
          errors = @keys.inject({}) do |container, data|
            key, instance = data
            recorder = ErrorRecorder.new
            instance.validate(env, recorder)
            container[key.to_sym] = recorder if !recorder.errors.empty?
            container
          end

          return if errors.empty?
          raise Errors::ConfigValidationFailed, :messages => Util::TemplateRenderer.render("config/validation_failed", :errors => errors)
        end

        # Returns the internal state of the root object. This is used
        # by outside classes when merging, and shouldn't be called directly.
        # Note the strange method name is to attempt to avoid any name
        # clashes with potential configuration keys.
        def __internal_state
          {
            "config_map" => @config_map,
            "keys"       => @keys
          }
        end
      end
    end
  end
end

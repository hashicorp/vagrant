module Vagrant
  module Config
    # This class is the "top" configure class, which handles registering
    # other configuration classes as well as validation of all configured
    # classes. This is the object which is returned by {Environment#config}
    # and has accessors to all other configuration classes.
    #
    # If you're looking to create your own configuration class, see {Base}.
    class Top < Base
      @@configures = {} if !defined?(@@configures)

      class << self
        # The list of registered configuration classes as well as the key
        # they're registered under.
        def configures_list
          @@configures ||= {}
        end

        # Registers a configuration class with the given key. This method shouldn't
        # be called. Instead, inherit from {Base} and call {Base.configures}.
        def configures(key, klass)
          configures_list[key] = klass
          attr_reader key.to_sym
        end
      end

      def initialize
        self.class.configures_list.each do |key, klass|
          config = klass.new
          config.top = self
          instance_variable_set("@#{key}".to_sym, config)
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
        errors = self.class.configures_list.inject({}) do |container, data|
          key, _ = data
          recorder = ErrorRecorder.new
          send(key.to_sym).validate(env, recorder)
          container[key.to_sym] = recorder if !recorder.errors.empty?
          container
        end

        return if errors.empty?
        raise Errors::ConfigValidationFailed, :messages => Util::TemplateRenderer.render("config/validation_failed", :errors => errors)
      end
    end
  end
end

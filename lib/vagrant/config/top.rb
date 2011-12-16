module Vagrant
  module Config
    # This class is the "top" configure class, which handles registering
    # other configuration classes as well as validation of all configured
    # classes. This is the object which is returned by {Environment#config}
    # and has accessors to all other configuration classes.
    #
    # If you're looking to create your own configuration class, see {Base}.
    class Top < Base
      def initialize
        @keys = {}
      end

      # We use method_missing as a way to get the configuration that is used
      # for Vagrant and load the proper configuration classes for each.
      def method_missing(name, *args)
        return @keys[name] if @keys.has_key?(name)

        config_klass = Vagrant.config_keys.get(name.to_sym)
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
    end
  end
end

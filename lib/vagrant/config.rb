require 'vagrant/config/base'
require 'vagrant/config/error_recorder'

module Vagrant
  # The config class is responsible for loading Vagrant configurations, which
  # are usually found in Vagrantfiles but may also be procs. The loading is done
  # by specifying a queue of files or procs that are for configuration, and then
  # executing them. The config loader will run each item in the queue, so that
  # configuration from later items overwrite that from earlier items. This is how
  # Vagrant "scoping" of Vagranfiles is implemented.
  #
  # If you're looking to create your own configuration classes, see {Base}.
  #
  # # Loading Configuration Files
  #
  # If you are in fact looking to load configuration files, then this is the
  # class you are looking for. Loading configuration is quite easy. The following
  # example assumes `env` is already a loaded instance of {Environment}:
  #
  #     config = Vagrant::Config.new(env)
  #     config.queue << "/path/to/some/Vagrantfile"
  #     result = config.load!
  #
  #     p "Your box is: #{result.vm.box}"
  #
  class Config
    extend Util::StackedProcRunner

    @@config = nil

    attr_reader :queue

    class << self
      # Resets the current loaded config object to the specified environment.
      # This clears the proc stack and initializes a new {Top} for loading.
      # This method shouldn't be called directly, instead use an instance of this
      # class for config loading.
      #
      # @param [Environment] env
      def reset!(env=nil)
        @@config = nil
        proc_stack.clear

        # Reset the configuration to the specified environment
        config(env)
      end

      # Returns the current {Top} configuration object. While this is still
      # here for implementation purposes, it shouldn't be called directly. Instead,
      # use an instance of this class.
      def config(env=nil)
        @@config ||= Config::Top.new(env)
      end

      # Adds the given proc/block to the stack of config procs which are all
      # run later on a single config object. This is the main way to configure
      # Vagrant, and is how all Vagrantfiles are formatted:
      #
      #     Vagrant::Config.run do |config|
      #       # ...
      #     end
      #
      def run(&block)
        push_proc(&block)
      end

      # Executes all the config procs onto the currently loaded {Top} object,
      # and returns the final configured object. This also validates the
      # configuration by calling {Top#validate!} on every configuration
      # class.
      def execute!
        config_object ||= config
        run_procs!(config_object)
        config_object
      end
    end

    # Initialize a {Config} object for the given {Environment}.
    #
    # @param [Environment] env Environment which config object will be part
    #   of.
    def initialize(env)
      @env = env
      @queue = []
    end

    # Loads the queue of files/procs, executes them in the proper
    # sequence, and returns the resulting configuration object.
    def load!
      self.class.reset!(@env)

      queue.flatten.each do |item|
        if item.is_a?(String) && File.exist?(item)
          begin
            load item
          rescue SyntaxError => e
            # Report syntax errors in a nice way for Vagrantfiles
            raise Errors::VagrantfileSyntaxError, :file => e.message
          end
        elsif item.is_a?(Proc)
          self.class.run(&item)
        end
      end

      return self.class.execute!
    end
  end

  class Config
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

      def initialize(env=nil)
        self.class.configures_list.each do |key, klass|
          config = klass.new
          config.env = env
          config.top = self
          instance_variable_set("@#{key}".to_sym, config)
        end

        @env = env
      end

      # Validates the configuration classes of this instance and raises an
      # exception if they are invalid. If you are implementing a custom configuration
      # class, the method you want to implement is {Base#validate}. This is
      # the method that checks all the validation, not one which defines
      # validation rules.
      def validate!
        # Validate each of the configured classes and store the results into
        # a hash.
        errors = self.class.configures_list.inject({}) do |container, data|
          key, _ = data
          recorder = ErrorRecorder.new
          send(key.to_sym).validate(recorder)
          container[key.to_sym] = recorder if !recorder.errors.empty?
          container
        end

        return if errors.empty?
        raise Errors::ConfigValidationFailed, :messages => Util::TemplateRenderer.render("config/validation_failed", :errors => errors)
      end
    end
  end
end

# The built-in configuration classes
require 'vagrant/config/vagrant'
require 'vagrant/config/ssh'
require 'vagrant/config/nfs'
require 'vagrant/config/vm'
require 'vagrant/config/package'

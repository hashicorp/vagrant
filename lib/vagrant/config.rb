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
  #     config = Vagrant::Config.new
  #     config.set(:first, "/path/to/some/Vagrantfile")
  #     config.set(:second, "/path/to/another/Vagrantfile")
  #     config.load_order = [:first, :second]
  #     result = config.load(env)
  #
  #     p "Your box is: #{result.vm.box}"
  #
  # The load order determines what order the config files specified are loaded.
  # If a key is not mentioned (for example if above the load order was set to
  # `[:first]`, therefore `:second` was not mentioned), then that config file
  # won't be loaded.
  class Config
    # An array of symbols specifying the load order for the procs.
    attr_accessor :load_order

    # This is the method which is called by all Vagrantfiles to configure Vagrant.
    # This method expects a block which accepts a single argument representing
    # an instance of the {Config::Top} class.
    #
    # Note that the block is not run immediately. Instead, it's proc is stored
    # away for execution later.
    def self.run(&block)
      # Store it for later
      @last_proc = block
    end

    # Returns the last proc which was activated for the class via {run}. This
    # also sets the last proc to `nil` so that calling this method multiple times
    # will not return duplicates.
    #
    # @return [Proc]
    def self.last_proc
      value = @last_proc
      @last_proc = nil
      value
    end

    def initialize
      @procs = {}
      @load_order = []
    end

    # Adds a Vagrantfile to be loaded to the queue of config procs. Note
    # that this causes the Vagrantfile file to be loaded at this point,
    # and it will never be loaded again.
    def set(key, path)
      @procs[key] = [path].flatten.map(&method(:proc_for))
    end

    # Loads the added procs using the set `load_order` attribute and returns
    # the {Config::Top} object result. The configuration is loaded for the
    # given {Environment} object.
    #
    # @param [Environment] env
    def load(env)
      config = Top.new(env)

      # Only run the procs specified in the load order, in the order
      # specified.
      load_order.each do |key|
        if @procs[key]
          @procs[key].each do |proc|
            proc.call(config) if proc
          end
        end
      end

      config
    end

    protected

    def proc_for(path)
      return nil if !path
      return path if path.is_a?(Proc)

      begin
        Kernel.load path if File.exist?(path)
        return self.class.last_proc
      rescue SyntaxError => e
        # Report syntax errors in a nice way for Vagrantfiles
        raise Errors::VagrantfileSyntaxError, :file => e.message
      end
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

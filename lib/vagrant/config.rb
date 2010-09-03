require 'vagrant/config/base'

module Vagrant
  # The config class is responsible for loading Vagrant configurations
  # (usually through Vagrantfiles).
  class Config
    extend Util::StackedProcRunner

    @@config = nil

    attr_reader :queue

    class << self
      def reset!(env=nil)
        @@config = nil
        proc_stack.clear

        # Reset the configuration to the specified environment
        config(env)
      end

      def configures(key, klass)
        config.class.configures(key, klass)
      end

      def config(env=nil)
        @@config ||= Config::Top.new(env)
      end

      def run(&block)
        push_proc(&block)
      end

      def execute!(config_object=nil)
        config_object ||= config

        run_procs!(config_object)
        config_object.loaded!
        config_object
      end
    end

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
          load item
        elsif item.is_a?(Proc)
          self.class.run(&item)
        end
      end

      return self.class.execute!
    end
  end

  class Config
    class Top < Base
      @@configures = []

      class << self
        def configures_list
          @@configures ||= []
        end

        def configures(key, klass)
          configures_list << [key, klass]
          attr_reader key.to_sym
        end
      end

      def initialize(env=nil)
        self.class.configures_list.each do |key, klass|
          config = klass.new
          config.env = env
          instance_variable_set("@#{key}".to_sym, config)
        end

        @loaded = false
        @env = env
      end

      def loaded?
        @loaded
      end

      def loaded!
        @loaded = true
      end

      # Deep clones the entire configuration tree using the marshalling
      # trick. All subclasses must be able to marshal properly.
      def deep_clone
        Marshal.load(Marshal.dump(self))
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

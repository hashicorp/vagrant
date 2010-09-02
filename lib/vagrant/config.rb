require 'vagrant/config/base'

module Vagrant
  class Config
    extend Util::StackedProcRunner

    @@config = nil

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

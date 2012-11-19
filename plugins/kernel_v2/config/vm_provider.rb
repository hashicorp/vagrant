require "log4r"

require "vagrant/util/stacked_proc_runner"

module VagrantPlugins
  module Kernel_V2
    # Represents a single configured provider for a VM. This may or may
    # not be a valid provider. Validation is deferred until later.
    class VagrantConfigProvider
      attr_reader :name
      attr_reader :config

      # Initializes a new provider configuration for a VM. This should
      # only be instantiated internally by calling `config.vm.provider`.
      #
      # @param [Symbol] name The name of the provider that is registered.
      def initialize(name, block)
        @name   = name
        @config = nil
        @logger = Log4r::Logger.new("vagrant::config::vm::provider")

        # If we were given a block to configure with, then let's try
        # to do that.
        load_config(block) if block
      end

      protected

      # This takes the config block given to define the provider and
      # attempts to turn this into a real configuration object. If the
      # provider plugin is not found then it is simply ignored. This allows
      # people to share Vagrantfiles that have configuration for providers
      # which may not be setup on every user's system.
      #
      # @param [Proc] config_proc
      def load_config(config_proc)
        config_class = Vagrant.plugin("2").manager.provider_configs[@name]
        if !config_class
          @logger.info("Provider config for #{@name} not found, ignoring that config.")
          return
        end

        @logger.info("Configuring provider #{@name} with #{config_class}")
        @config = config_class.new
        config_proc.call(@config)
      end
    end
  end
end

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

        # Attempt to find the configuration class for this provider and
        # load the configuration.
        config_class = Vagrant.plugin("2").manager.provider_configs[@name]
        if !config_class
          @logger.info("Provider config for #{@name} not found, ignoring config.")
          return
        end

        @logger.info("Configuring provider #{@name} with #{config_class}")
        @config = config_class.new
        block.call(@config) if block
      end
    end
  end
end

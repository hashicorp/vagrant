require "log4r"

require "vagrant/util/stacked_proc_runner"

module VagrantPlugins
  module Kernel_V2
    # Represents a single configured provider for a VM. This may or may
    # not be a valid provider. Validation is deferred until later.
    class VagrantConfigProvider
      # This is the name of the provider, as a symbol.
      #
      # @return [Symbol]
      attr_reader :name

      # The compiled configuration. This is only available after finalizing.
      #
      # @return [Object]
      attr_reader :config

      # Initializes a new provider configuration for a VM. This should
      # only be instantiated internally by calling `config.vm.provider`.
      #
      # @param [Symbol] name The name of the provider that is registered.
      def initialize(name)
        @name   = name
        @config = nil
        @config_blocks = []
        @logger = Log4r::Logger.new("vagrant::config::vm::provider")

        # Attempt to find the configuration class for this provider and
        # load the configuration.
        @config_class = Vagrant.plugin("2").manager.provider_configs[@name]
        if !@config_class
          @logger.info("Provider config for #{@name} not found, ignoring config.")
        end
      end

      # This adds a configuration block to the list of configuration
      # blocks to execute when compiling the configuration.
      def add_config_block(block)
        @config_blocks << block
      end

      # This is called to compile the configuration
      def finalize!
        if @config_class
          @logger.info("Configuring provider #{@name} with #{@config_class}")

          # Call each block in order with the config object
          @config = @config_class.new
          @config_blocks.each { |b| b.call(@config) }

          # Finalize the configuration
          @config.finalize!
        end
      end
    end
  end
end

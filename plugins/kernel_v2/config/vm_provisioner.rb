require 'log4r'

module VagrantPlugins
  module Kernel_V2
    # Represents a single configured provisioner for a VM.
    class VagrantConfigProvisioner
      # The name of the provisioner that should be registered
      # as a plugin.
      #
      # @return [Symbol]
      attr_reader :name

      # The configuration associated with the provisioner, if there is any.
      #
      # @return [Object]
      attr_reader :config

      def initialize(name, options=nil, &block)
        @logger = Log4r::Logger.new("vagrant::config::vm::provisioner")
        @logger.debug("Provisioner defined: #{name}")

        @config  = nil
        @invalid = false
        @name    = name

        # Attempt to find the provisioner...
        if !Vagrant.plugin("2").manager.provisioners[name]
          @logger.warn("Provisioner '#{name}' not found.")
          @invalid = true
        end

        # Attempt to find the configuration class for this provider
        # if it exists and load the configuration.
        config_class = Vagrant.plugin("2").manager.provisioner_configs[@name]
        if !config_class
          @logger.info("Provisioner config for '#{@name}' not found. Ignoring config.")
          return
        end

        @config = config_class.new
        @config.set_options(options) if options
        block.call(@config) if block
        @config.finalize!
      end

      # Returns whether the provisioner used was invalid or not. A provisioner
      # is invalid if it can't be found.
      #
      # @return [Boolean]
      def invalid?
        @invalid
      end
    end
  end
end

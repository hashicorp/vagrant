module Vagrant
  module Config
    # Contains loaded configuration values and provides access to those
    # values.
    #
    # This is the class returned when loading configuration and stores
    # the completely loaded configuration values. This class is meant to
    # be immutable.
    class Container
      attr_reader :global
      attr_reader :vms

      # Initializes the configuration container.
      #
      # @param [Top] global Top-level configuration for the global
      #   applicatoin.
      # @param [Array] vms Array of VM configurations.
      def initialize(global, vms)
        @global = global
        @vms    = []
        @vm_configs = {}

        vms.each do |vm_config|
          @vms << vm_config.vm.name
          @vm_configs[vm_config.vm.name] = vm_config
        end
      end

      # This returns the configuration for a specific virtual machine.
      # The values for this configuration are usually pertinent to a
      # single virtual machine and do not affect the system globally.
      def for_vm(name)
        @vm_configs[name]
      end
    end
  end
end

module VagrantPlugins
  module ProviderVirtualBox
    class Config < Vagrant.plugin("2", :config)
      # An array of customizations to make on the VM prior to booting it.
      #
      # @return [Array]
      attr_reader :customizations

      # If set to `true`, then VirtualBox will be launched with a GUI.
      #
      # @return [Boolean]
      attr_accessor :gui

      # The defined network adapters.
      #
      # @return [Hash]
      attr_reader :network_adapters

      def initialize
        @customizations   = []
        @network_adapters = {}
        @gui              = UNSET_VALUE

        # We require that network adapter 1 is a NAT device.
        network_adapter(1, :nat)
      end

      # Customize the VM by calling `VBoxManage` with the given
      # arguments.
      #
      # When called multiple times, the customizations will be applied
      # in the order given.
      #
      # The special `:name` parameter in the command will be replaced with
      # the unique ID or name of the virtual machine. This is useful for
      # parameters to `modifyvm` and the like.
      #
      # @param [Array] command An array of arguments to pass to
      # VBoxManage.
      def customize(command)
        @customizations << command
      end

      # This defines a network adapter that will be added to the VirtualBox
      # virtual machine in the given slot.
      #
      # @param [Integer] slot The slot for this network adapter.
      # @param [Symbol] type The type of adapter.
      def network_adapter(slot, type, *args)
        @network_adapters[slot] = [type, args]
      end

      # This is the hook that is called to finalize the object before it
      # is put into use.
      def finalize!
        # Default is to not show a GUI
        @gui = false if @gui == UNSET_VALUE
      end
    end
  end
end

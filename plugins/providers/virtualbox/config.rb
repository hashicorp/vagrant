module VagrantPlugins
  module ProviderVirtualBox
    class Config < Vagrant.plugin("2", :config)
      attr_reader :customizations

      # If set to `true`, then VirtualBox will be launched with a GUI.
      attr_accessor :gui

      def initialize
        @customizations = []
        @gui = UNSET_VALUE
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

      # This is the hook that is called to finalize the object before it
      # is put into use.
      def finalize!
        # Default is to not show a GUI
        @gui = false if @gui == UNSET_VALUE
      end
    end
  end
end

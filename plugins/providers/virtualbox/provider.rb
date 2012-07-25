module VagrantPlugins
  module ProviderVirtualBox
    class Provider < Vagrant.plugin("1", :provider)
      def initialize(machine)
        @machine = machine
        @driver  = Driver::Meta.new(@machine.id)
      end

      # Return the state of VirtualBox virtual machine by actually
      # querying VBoxManage.
      def state
        return :not_created if !@driver.uuid
        state = @driver.read_state
        return :unknown if !state
        state
      end
    end
  end
end

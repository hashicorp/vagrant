module VagrantPlugins
  module ProviderVirtualBox
    class Provider < Vagrant.plugin("1", :provider)
      def initialize(machine)
        @machine = machine
        @driver  = Driver::Meta.new(@machine.id)
      end

      # @see Vagrant::Plugin::V1::Provider#action
      def action(name)
        # Attempt to get the action method from the Action class if it
        # exists, otherwise return nil to show that we don't support the
        # given action.
        action_method = "action_#{name}"
        return Action.send(action_method) if Action.respond_to?(action_method)
        nil
      end

      # Returns a human-friendly string version of this provider which
      # includes the machine's ID that this provider represents, if it
      # has one.
      #
      # @return [String]
      def to_s
        id = @machine.id ? @machine.id : "new VM"
        "VirtualBox (#{id})"
      end

      # Return the state of VirtualBox virtual machine by actually
      # querying VBoxManage.
      #
      # @return [Symbol]
      def state
        return :not_created if !@driver.uuid
        state = @driver.read_state
        return :unknown if !state
        state
      end
    end
  end
end

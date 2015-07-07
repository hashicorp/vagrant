require "log4r"

module VagrantPlugins
  module ProviderVirtualBox
    class Provider < Vagrant.plugin("2", :provider)
      attr_reader :driver

      def self.usable?(raise_error=false)
        # Instantiate the driver, which will determine the VirtualBox
        # version and all that, which checks for VirtualBox being present
        Driver::Meta.new
        true
      rescue Vagrant::Errors::VirtualBoxInvalidVersion
        raise if raise_error
        return false
      rescue Vagrant::Errors::VirtualBoxNotDetected
        raise if raise_error
        return false
      end

      def initialize(machine)
        @logger  = Log4r::Logger.new("vagrant::provider::virtualbox")
        @machine = machine

        # This method will load in our driver, so we call it now to
        # initialize it.
        machine_id_changed
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

      # If the machine ID changed, then we need to rebuild our underlying
      # driver.
      def machine_id_changed
        id = @machine.id

        begin
          @logger.debug("Instantiating the driver for machine ID: #{@machine.id.inspect}")
          @driver = Driver::Meta.new(id)
        rescue Driver::Meta::VMNotFound
          # The virtual machine doesn't exist, so we probably have a stale
          # ID. Just clear the id out of the machine and reload it.
          @logger.debug("VM not found! Clearing saved machine ID and reloading.")
          id = nil
          retry
        end
      end

      # Returns the SSH info for accessing the VirtualBox VM.
      def ssh_info
        # If the VM is not running that we can't possibly SSH into it
        return nil if state.id != :running

        # Return what we know. The host is always "127.0.0.1" because
        # VirtualBox VMs are always local. The port we try to discover
        # by reading the forwarded ports.
        return {
          host: "127.0.0.1",
          port: @driver.ssh_port(@machine.config.ssh.guest_port)
        }
      end

      # Return the state of VirtualBox virtual machine by actually
      # querying VBoxManage.
      #
      # @return [Symbol]
      def state
        # We have to check if the UID matches to avoid issues with
        # VirtualBox.
        uid = @machine.uid
        if uid && uid.to_s != Process.uid.to_s
          raise Vagrant::Errors::VirtualBoxUserMismatch,
            original_uid: uid.to_s,
            uid: Process.uid.to_s
        end

        # Determine the ID of the state here.
        state_id = nil
        state_id = :not_created if !@driver.uuid
        state_id = @driver.read_state if !state_id
        state_id = :unknown if !state_id

        # Translate into short/long descriptions
        short = state_id.to_s.gsub("_", " ")
        long  = I18n.t("vagrant.commands.status.#{state_id}")

        # If we're not created, then specify the special ID flag
        if state_id == :not_created
          state_id = Vagrant::MachineState::NOT_CREATED_ID
        end

        # Return the state
        Vagrant::MachineState.new(state_id, short, long)
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
    end
  end
end

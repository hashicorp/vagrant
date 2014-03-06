require "log4r"

require_relative "driver"
require_relative "plugin"

require "vagrant/util/platform"
require "vagrant/util/powershell"

module VagrantPlugins
  module HyperV
    class Provider < Vagrant.plugin("2", :provider)
      attr_reader :driver

      def initialize(machine)
        @machine = machine

        if !Vagrant::Util::Platform.windows?
          raise Errors::WindowsRequired
        end

        if !Vagrant::Util::Platform.windows_admin?
          raise Errors::AdminRequired
        end

        if !Vagrant::Util::PowerShell.available?
          raise Errors::PowerShellRequired
        end

        # This method will load in our driver, so we call it now to
        # initialize it.
        machine_id_changed
      end

      def action(name)
        # Attempt to get the action method from the Action class if it
        # exists, otherwise return nil to show that we don't support the
        # given action.
        action_method = "action_#{name}"
        return Action.send(action_method) if Action.respond_to?(action_method)
        nil
      end

      def machine_id_changed
        @driver = Driver.new(@machine.id)
      end

      def state
        state_id = nil
        state_id = :not_created if !@machine.id

        if !state_id
          # Run a custom action we define called "read_state" which does
          # what it says. It puts the state in the `:machine_state_id`
          # key in the environment.
          env = @machine.action(:read_state)
          state_id = env[:machine_state_id]
        end

        # Get the short and long description
        short = state_id.to_s
        long  = ""

        # Return the MachineState object
        Vagrant::MachineState.new(state_id, short, long)
      end

      def to_s
        id = @machine.id.nil? ? "new" : @machine.id
        "Hyper-V (#{id})"
      end

      def ssh_info
        # We can only SSH into a running machine
        return nil if state.id != :running

        # Read the IP of the machine using Hyper-V APIs
        network = @driver.read_guest_ip
        return nil if !network["ip"]

        {
          host: network["ip"],
          port: 22,
        }
      end
    end
  end
end

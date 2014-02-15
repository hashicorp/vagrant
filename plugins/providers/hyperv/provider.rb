#-------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the MIT License.
#--------------------------------------------------------------------------
require "log4r"
require "vagrant"

module VagrantPlugins
  module HyperV
    class Provider < Vagrant.plugin("2", :provider)

      def initialize(machine)
        @machine = machine
      end

      def action(name)
        # Attempt to get the action method from the Action class if it
        # exists, otherwise return nil to show that we don't support the
        # given action.
        action_method = "action_#{name}"
        return Action.send(action_method) if Action.respond_to?(action_method)
        nil
      end

      def state
        # Run a custom action we define called "read_state" which does
        # what it says. It puts the state in the `:machine_state_id`
        # key in the environment.
        env = @machine.action("read_state")
        state_id = env[:machine_state_id]

        # Get the short and long description
        # TODO
        short = "Machine's current state is #{state_id}"
        long  = ""

        # Return the MachineState object
        Vagrant::MachineState.new(state_id, short, long)
      end

      def to_s
        id = @machine.id.nil? ? "new" : @machine.id
        "Hyper-V (#{id})"
      end

      def ssh_info
        # Run a custom action called "read_guest_ip" which does what it
        # says and puts the resulting SSH info into the `:machine_ssh_info`
        # key in the environment.
        env = @machine.action("read_guest_ip")
        if env[:machine_ssh_info]
          env[:machine_ssh_info].merge!(:port => 22)
        end
      end

      def driver
        @driver ||= Driver::Base.new()
      end
    end
  end
end

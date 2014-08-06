require "vagrant"

module VagrantPlugins
  module GuestNixos
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        # For some reason our test passes on Windows, so just short
        # circuit because we're not Windows.
        if machine.config.vm.communicator == :winrm
          return false
        end

        machine.communicate.test("test -f /run/current-system/nixos-version")
      end
    end
  end
end

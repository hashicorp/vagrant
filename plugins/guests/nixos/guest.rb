require "vagrant"

module VagrantPlugins
  module GuestNixos
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        machine.communicate.test("test -f /run/current-system/nixos-version")
      end
    end
  end
end

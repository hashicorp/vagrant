require "vagrant"

module VagrantPlugins
  module GuestFedora
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        machine.communicate.test("grep 'Fedora release 1[678]' /etc/redhat-release")
      end
    end
  end
end

require "vagrant"

module VagrantPlugins
  module GuestFedora
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        machine.communicate.test("grep 'Fedora release 1[6789]\\|Fedora release 2[0-9]' /etc/redhat-release")
      end
    end
  end
end

require 'vagrant'

module VagrantPlugins
  module GuestFedora
    class Guest < Vagrant.plugin('2', :guest)
      def detect?(machine)
        machine.communicate.test("grep 'Fedora release [12][67890]' /etc/redhat-release")
      end
    end
  end
end

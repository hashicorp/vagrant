require "vagrant"

module VagrantPlugins
  module GuestNetBSD
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        machine.communicate.test("uname -s | grep NetBSD")
      end
    end
  end
end

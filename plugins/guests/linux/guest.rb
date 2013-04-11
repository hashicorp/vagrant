require "vagrant"

module VagrantPlugins
  module GuestLinux
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        machine.communicate.test("uname -s | grep 'Linux'")
      end
    end
  end
end

require "vagrant"

module VagrantPlugins
  module GuestMINIX
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        machine.communicate.test("uname -s | grep Minix")
      end
    end
  end
end

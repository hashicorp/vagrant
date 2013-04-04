require "vagrant"

module VagrantPlugins
  module GuestArch
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        machine.communicate.test("cat /etc/arch-release")
      end
    end
  end
end

require "vagrant"

module VagrantPlugins
  module GuestSuse
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        machine.communicate.test("cat /etc/SuSE-release")
      end
    end
  end
end

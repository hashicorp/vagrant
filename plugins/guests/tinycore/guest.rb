require "vagrant"

module VagrantPlugins
  module GuestTinyCore
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        machine.communicate.test("cat /etc/issue | grep 'Core Linux'")
      end
    end
  end
end

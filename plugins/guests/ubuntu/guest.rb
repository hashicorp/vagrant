require "vagrant"

module VagrantPlugins
  module GuestUbuntu
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        machine.communicate.test("cat /etc/issue | grep 'Ubuntu'")
      end
    end
  end
end

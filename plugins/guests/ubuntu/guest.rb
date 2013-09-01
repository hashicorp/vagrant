require "vagrant"

require Vagrant.source_root.join("plugins/guests/debian/guest")

module VagrantPlugins
  module GuestUbuntu
    class Guest < VagrantPlugins::GuestDebian::Guest
      def detect?(machine)
        machine.communicate.test("cat /etc/issue | grep 'Ubuntu'")
      end
    end
  end
end

require "vagrant"

require Vagrant.source_root.join("plugins/guests/ubuntu/guest")

module VagrantPlugins
  module GuestMint
    class Guest < VagrantPlugins::GuestUbuntu::Guest
      def detect?(machine)
        machine.communicate.test("cat /etc/issue | grep 'Linux Mint'")
      end
    end
  end
end

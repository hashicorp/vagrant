require "vagrant"

module VagrantPlugins
  module GuestMint
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        machine.communicate.test("cat /etc/issue | grep 'Linux Mint'")
      end
    end
  end
end

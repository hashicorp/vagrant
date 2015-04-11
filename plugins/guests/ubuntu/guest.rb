require "vagrant"

module VagrantPlugins
  module GuestUbuntu
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        machine.communicate.test("[ -x /usr/bin/lsb_release ] && /usr/bin/lsb_release -i 2>/dev/null | grep Ubuntu")
      end
    end
  end
end

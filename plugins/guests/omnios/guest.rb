require "vagrant"

module VagrantPlugins
  module GuestOmniOS
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        machine.communicate.test("cat /etc/release | grep -i OmniOS")
      end
    end
  end
end

require "vagrant"

module VagrantPlugins
  module GuestCoreOS
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        machine.communicate.test("(cat /etc/os-release | grep ID=coreos) || (cat /etc/os-release | grep -E 'ID_LIKE=.*coreos.*')")
      end
    end
  end
end

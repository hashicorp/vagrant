module VagrantPlugins
  module GuestGentoo
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        machine.communicate.test("cat /etc/gentoo-release")
      end
    end
  end
end

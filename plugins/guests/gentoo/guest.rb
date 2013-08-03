module VagrantPlugins
  module GuestGentoo
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        machine.communicate.test("grep Gentoo /etc/gentoo-release")
      end
    end
  end
end

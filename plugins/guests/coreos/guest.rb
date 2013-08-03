module VagrantPlugins
  module GuestCoreOS
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        machine.communicate.test("cat /etc/gentoo-release | grep CoreOS")
      end
    end
  end
end

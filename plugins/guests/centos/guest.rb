module VagrantPlugins
  module GuestCentos
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        machine.communicate.test("cat /etc/centos-release")
      end
    end
  end
end

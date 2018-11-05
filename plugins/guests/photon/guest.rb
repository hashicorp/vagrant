module VagrantPlugins
  module GuestPhoton
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        machine.communicate.test("cat /etc/photon-release | grep 'VMware Photon'")
      end
    end
  end
end

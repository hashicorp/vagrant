module VagrantPlugins
  module GuestALT
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        machine.communicate.test("cat /etc/altlinux-release")
      end
    end
  end
end

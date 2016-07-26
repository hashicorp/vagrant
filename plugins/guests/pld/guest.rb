module VagrantPlugins
  module GuestPld
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        machine.communicate.test("cat /etc/pld-release")
      end
    end
  end
end

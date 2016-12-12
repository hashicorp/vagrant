module VagrantPlugins
  module GuestRedHat
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        machine.communicate.test("cat /etc/redhat-release")
      end
    end
  end
end

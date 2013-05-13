module VagrantPlugins
  module GuestDebian
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        machine.communicate.test("cat /etc/issue | grep 'Debian'")
      end
    end
  end
end

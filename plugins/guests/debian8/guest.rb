module VagrantPlugins
  module GuestDebian8
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        machine.communicate.test("cat /etc/issue | grep 'Debian' | grep '8'")
      end
    end
  end
end

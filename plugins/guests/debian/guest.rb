module VagrantPlugins
  module GuestDebian
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        machine.communicate.test("cat /etc/issue | grep 'Debian' | grep -v '8'")
      end
    end
  end
end

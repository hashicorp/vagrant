module VagrantPlugins
  module GuestUbuntu
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        machine.communicate.test('grep ID=ubuntu /etc/os-release')
      end
    end
  end
end

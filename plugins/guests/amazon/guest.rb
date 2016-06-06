module VagrantPlugins
  module GuestAmazon
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        machine.communicate.test("grep 'Amazon Linux AMI' /etc/os-release")
      end
    end
  end
end

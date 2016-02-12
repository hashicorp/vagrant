module VagrantPlugins
  module GuestAlpine
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        machine.communicate.test("grep Alpine /etc/os-release")
      end
    end
  end
end

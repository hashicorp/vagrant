module VagrantPlugins
  module GuestUbuntu
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        machine.communicate.test("test -r /etc/os-release && . /etc/os-release && test xubuntu = x$ID")
      end
    end
  end
end

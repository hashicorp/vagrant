require "vagrant"

module VagrantPlugins
  module GuestEsxi
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        machine.communicate.test("uname -s | grep VMkernel")
      end
    end
  end
end

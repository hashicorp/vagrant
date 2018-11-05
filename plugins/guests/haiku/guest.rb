require "vagrant"

module VagrantPlugins
  module GuestHaiku
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        machine.communicate.test("uname -o | grep 'Haiku'")
      end
    end
  end
end

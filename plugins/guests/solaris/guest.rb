require "vagrant"

module VagrantPlugins
  module GuestSolaris
    # A general Vagrant system implementation for "solaris".
    #
    # Contributed by Blake Irvin <b.irvin@modcloth.com>
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        machine.communicate.test("uname -sr | grep SunOS | grep -v 5.11")
      end
    end
  end
end

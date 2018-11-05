# A general Vagrant system implementation for "solaris 11".
#
# Contributed by Jan Thomas Moldung <janth@moldung.no>

require "vagrant"

module VagrantPlugins
  module GuestSolaris11
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        success = machine.communicate.test("grep 'Solaris 11' /etc/release")
        return success if success

        # for solaris derived guests like openindiana
        machine.communicate.test("uname -sr | grep 'SunOS 5.11'")
      end
    end
  end
end

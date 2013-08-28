# A general Vagrant system implementation for "solaris 11".
#
# Contributed by Jan Thomas Moldung <janth@moldung.no>

require "vagrant"

module VagrantPlugins
  module GuestSolaris11
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        machine.communicate.test("uname -s | grep SunOS")
      end
    end
  end
end

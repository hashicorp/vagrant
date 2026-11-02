# Copyright IBM Corp. 2010, 2025
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module GuestDragonFlyBSD
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        machine.communicate.test("uname -s | grep -i 'DragonFly'")
      end
    end
  end
end

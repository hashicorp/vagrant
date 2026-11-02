# Copyright IBM Corp. 2010, 2025
# SPDX-License-Identifier: MIT

require "vagrant"

module VagrantPlugins
  module GuestOpenBSD
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        machine.communicate.test("uname -s | grep 'OpenBSD'")
      end
    end
  end
end

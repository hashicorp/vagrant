# Copyright IBM Corp. 2010, 2025
# SPDX-License-Identifier: BUSL-1.1

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

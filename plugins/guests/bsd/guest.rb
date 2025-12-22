# Copyright IBM Corp. 2010, 2025
# SPDX-License-Identifier: BUSL-1.1

module VagrantPlugins
  module GuestBSD
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        machine.communicate.test("uname -s | grep -i 'BSD'")
      end
    end
  end
end

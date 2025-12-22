# Copyright IBM Corp. 2010, 2025
# SPDX-License-Identifier: BUSL-1.1

module VagrantPlugins
  module GuestWindows
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        # See if the Windows directory is present.
        machine.communicate.test("test -d $Env:SystemRoot")
      end
    end
  end
end

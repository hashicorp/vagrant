# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

module VagrantPlugins
  module GuestFuntoo
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        machine.communicate.test("grep Funtoo /etc/gentoo-release")
      end
    end
  end
end

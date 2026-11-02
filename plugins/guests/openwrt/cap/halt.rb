# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module GuestOpenWrt
    module Cap
      class Halt
        def self.halt(machine)
          begin
            machine.communicate.execute("halt")
          rescue IOError, Vagrant::Errors::SSHDisconnected
            # Ignore, this probably means connection closed because it
            # shut down.
          end
        end
      end
    end
  end
end

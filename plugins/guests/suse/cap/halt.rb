# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module GuestSUSE
    module Cap
      class Halt
        def self.halt(machine)
          begin
            if machine.communicate.test("test -e /usr/bin/systemctl")
              machine.communicate.sudo("/usr/bin/systemctl poweroff &")
            else
              machine.communicate.sudo("/sbin/shutdown -h now &")
            end
          rescue IOError, Vagrant::Errors::SSHDisconnected
            # Do nothing, because it probably means the machine shut down
            # and SSH connection was lost.
          end
        end
      end
    end
  end
end

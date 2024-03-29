# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

module VagrantPlugins
  module GuestArch
    module Cap
      class SMB
        def self.smb_install(machine)
          comm = machine.communicate
          if !comm.test("test -f /usr/bin/mount.cifs")
            comm.sudo <<-EOH.gsub(/^ {14}/, '')
              pacman -Sy --noconfirm
              pacman -S --noconfirm smbclient cifs-utils
            EOH
          end
        end
      end
    end
  end
end

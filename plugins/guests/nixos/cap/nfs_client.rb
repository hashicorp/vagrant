# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

module VagrantPlugins
  module GuestNixos
    module Cap
      class NFSClient
        def self.nfs_client_installed(machine)
          machine.communicate.test("test -x /run/current-system/sw/sbin/mount.nfs")
        end
      end
    end
  end
end

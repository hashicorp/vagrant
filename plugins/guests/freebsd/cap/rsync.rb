# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../synced_folders/rsync/default_unix_cap"

module VagrantPlugins
  module GuestFreeBSD
    module Cap
      class RSync
        extend VagrantPlugins::SyncedFolderRSync::DefaultUnixCap

        def self.rsync_install(machine)
          machine.communicate.sudo("pkg install -y rsync")
        end
      end
    end
  end
end

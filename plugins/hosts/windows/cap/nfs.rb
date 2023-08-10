# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

module VagrantPlugins
  module HostWindows
    module Cap
      class NFS
        def self.nfs_installed(env)
          false
        end
      end
    end
  end
end

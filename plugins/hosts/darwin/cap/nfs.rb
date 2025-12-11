# Copyright IBM Corp. 2010, 2025
# SPDX-License-Identifier: BUSL-1.1

module VagrantPlugins
  module HostDarwin
    module Cap
      class NFS
        def self.nfs_exports_template(environment)
          "nfs/exports_darwin"
        end
      end
    end
  end
end

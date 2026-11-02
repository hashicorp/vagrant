# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module HyperV
    module Cap
      module SnapshotList
        def self.snapshot_list(machine)
          machine.provider.driver.list_snapshots
        end
      end
    end
  end
end

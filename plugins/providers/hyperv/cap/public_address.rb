# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

module VagrantPlugins
  module HyperV
    module Cap
      module PublicAddress
        def self.public_address(machine)
          return nil if machine.state.id != :running

          ssh_info = machine.ssh_info
          return nil if !ssh_info
          ssh_info[:host]
        end
      end
    end
  end
end

# Copyright IBM Corp. 2010, 2025
# SPDX-License-Identifier: BUSL-1.1

module VagrantPlugins
  module DockerProvider
    module Cap
      module ProxyMachine
        def self.proxy_machine(machine)
          return nil if !machine.provider.host_vm?
          machine.provider.host_vm
        end
      end
    end
  end
end

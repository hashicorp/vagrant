# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module DockerProvisioner
    module Cap
      module Debian
        module DockerStartService
          def self.docker_start_service(machine)
            machine.communicate.sudo("service docker start")
          end
        end
      end
    end
  end
end

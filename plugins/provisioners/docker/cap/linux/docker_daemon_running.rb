# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

module VagrantPlugins
  module DockerProvisioner
    module Cap
      module Linux
        module DockerDaemonRunning
          def self.docker_daemon_running(machine)
            machine.communicate.test("test -f /var/run/docker.pid")
          end
        end
      end
    end
  end
end

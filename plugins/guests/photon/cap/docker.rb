# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

module VagrantPlugins
  module GuestPhoton
    module Cap
      module Docker
        def self.docker_daemon_running(machine)
          machine.communicate.test('test -S /run/docker.sock')
        end
      end
    end
  end
end

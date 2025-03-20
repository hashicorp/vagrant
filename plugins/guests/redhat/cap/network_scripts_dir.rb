# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

module VagrantPlugins
  module GuestRedHat
    module Cap
      class NetworkScriptsDir
        def self.network_scripts_dir(machine)
          if machine.communicate.test("test -d /etc/sysconfig/network-scripts")
            "/etc/sysconfig/network-scripts"
          else
            "/etc/NetworkManager/system-connections"
          end
        end
      end
    end
  end
end

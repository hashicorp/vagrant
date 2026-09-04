# Copyright IBM Corp. 2010, 2025
# SPDX-License-Identifier: BUSL-1.1

module VagrantPlugins
  module GuestSUSE
    module Cap
      class NetworkScriptsDir
        def self.network_scripts_dir(machine)
          if machine.communicate.test("test -d /etc/sysconfig/network")
            "/etc/sysconfig/network"
          else
            "/etc/NetworkManager/system-connections"
          end
        end
      end
    end
  end
end

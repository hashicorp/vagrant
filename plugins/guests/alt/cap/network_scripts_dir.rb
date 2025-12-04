# Copyright IBM Corp. 2010, 2025
# SPDX-License-Identifier: BUSL-1.1

module VagrantPlugins
  module GuestALT
    module Cap
      class NetworkScriptsDir
        def self.network_scripts_dir(machine)
          "/etc/net"
        end
      end
    end
  end
end

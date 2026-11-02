# Copyright IBM Corp. 2010, 2025
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module GuestSUSE
    module Cap
      class NetworkScriptsDir
        def self.network_scripts_dir(machine)
          "/etc/sysconfig/network"
        end
      end
    end
  end
end

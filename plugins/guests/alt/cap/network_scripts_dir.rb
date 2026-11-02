# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

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

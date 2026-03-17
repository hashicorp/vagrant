# Copyright IBM Corp. 2010, 2025
# SPDX-License-Identifier: BUSL-1.1

module VagrantPlugins
  module GuestSUSE
    module Cap
      class NetworkScriptsDir
        def self.network_scripts_dir(machine)
          # For OpenSUSE Leap 16+ with NetworkManager, use NetworkManager path
          if VagrantPlugins::GuestSUSE::Guest.leap_16_or_newer?(machine) && 
             VagrantPlugins::GuestSUSE::Guest.network_manager_available?(machine)
            "/etc/NetworkManager/system-connections"
          else
            # For older versions or when NetworkManager is not available, use legacy path
            "/etc/sysconfig/network"
          end
        end
      end
    end
  end
end

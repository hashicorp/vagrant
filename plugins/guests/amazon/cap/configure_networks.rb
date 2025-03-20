# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

require_relative "../../debian/cap/configure_networks"
require_relative "../../redhat/cap/configure_networks"

module VagrantPlugins
  module GuestAmazon
    module Cap
      class ConfigureNetworks
        extend Vagrant::Util::GuestInspection::Linux

        def self.configure_networks(machine, networks)
          # If the guest is using networkd, call the debian capability
          # as it will handle networkd. Otherwise, fallback to using
          # the RHEL capability.
          if systemd_networkd?(machine.communicate)
            VagrantPlugins::GuestDebian::Cap::ConfigureNetworks.configure_networks(machine, networks)
          else
            VagrantPlugins::GuestRedHat::Cap::ConfigureNetworks.configure_networks(machine, networks)
          end
        end
      end
    end
  end
end

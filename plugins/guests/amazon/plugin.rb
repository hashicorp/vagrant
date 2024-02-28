# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

require "vagrant"

module VagrantPlugins
  module GuestAmazon
    class Plugin < Vagrant.plugin("2")
      name "Amazon Linux guest"
      description "Amazon linux guest support."

      guest(:amazon, :redhat) do
        require_relative "guest"
        Guest
      end

      guest_capability(:amazon, :configure_networks) do
        require_relative "cap/configure_networks"
        Cap::ConfigureNetworks
      end

      guest_capability(:amazon, :flavor) do
        require_relative "cap/flavor"
        Cap::Flavor
      end
    end
  end
end

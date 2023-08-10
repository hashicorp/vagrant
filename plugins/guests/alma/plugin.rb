# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

require "vagrant"

module VagrantPlugins
  module GuestAlma
    class Plugin < Vagrant.plugin("2")
      name "Alma guest"
      description "Alma guest support."

      guest(:alma, :redhat) do
        require_relative "guest"
        Guest
      end

      guest_capability(:alma, :flavor) do
        require_relative "cap/flavor"
        Cap::Flavor
      end
    end
  end
end

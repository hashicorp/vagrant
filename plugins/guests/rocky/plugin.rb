# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require "vagrant"

module VagrantPlugins
  module GuestRocky
    class Plugin < Vagrant.plugin("2")
      name "Rocky guest"
      description "Rocky guest support."

      guest(:rocky, :redhat) do
        require_relative "guest"
        Guest
      end

      guest_capability(:rocky, :flavor) do
        require_relative "cap/flavor"
        Cap::Flavor
      end
    end
  end
end

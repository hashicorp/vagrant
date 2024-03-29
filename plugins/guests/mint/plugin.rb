# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

require "vagrant"

module VagrantPlugins
  module GuestMint
    class Plugin < Vagrant.plugin("2")
      name "Mint guest"
      description "Mint guest support."

      guest(:mint, :ubuntu) do
        require_relative "guest"
        Guest
      end
    end
  end
end

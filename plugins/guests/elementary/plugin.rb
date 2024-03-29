# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

require "vagrant"

module VagrantPlugins
  module GuestElementary
    class Plugin < Vagrant.plugin("2")
      name "Elementary guest"
      description "Elementary guest support."

      guest(:elementary, :ubuntu) do
        require_relative "guest"
        Guest
      end
    end
  end
end

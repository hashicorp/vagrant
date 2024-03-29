# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

require "vagrant"

module VagrantPlugins
  module GuestTrisquel
    class Plugin < Vagrant.plugin("2")
      name "Trisquel guest"
      description "Trisquel guest support."

      guest(:trisquel, :ubuntu) do
        require_relative "guest"
        Guest
      end
    end
  end
end

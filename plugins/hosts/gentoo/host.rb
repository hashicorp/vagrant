# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require "vagrant"

module VagrantPlugins
  module HostGentoo
    class Host < Vagrant.plugin("2", :host)
      def detect?(env)
        File.exist?("/etc/gentoo-release")
      end
    end
  end
end

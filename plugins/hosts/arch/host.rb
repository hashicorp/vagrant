# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

require "vagrant"

module VagrantPlugins
  module HostArch
    class Host < Vagrant.plugin("2", :host)
      def detect?(env)
        File.exist?("/etc/arch-release") && !File.exist?("/etc/artix-release")
      end
    end
  end
end

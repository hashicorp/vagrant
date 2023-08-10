# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

require "vagrant"

module VagrantPlugins
  module HostALT
    class Host < Vagrant.plugin("2", :host)
      def detect?(env)
        File.exist?("/etc/altlinux-release")
      end
    end
  end
end

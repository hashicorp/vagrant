# Copyright IBM Corp. 2010, 2025
# SPDX-License-Identifier: MIT

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

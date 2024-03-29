# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

require "vagrant"

module VagrantPlugins
  module HostLinux
    # Represents a Linux based host, such as Ubuntu.
    class Host < Vagrant.plugin("2", :host)
      def detect?(env)
        Vagrant::Util::Platform.linux?
      end
    end
  end
end

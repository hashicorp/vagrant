# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

require "vagrant/util/platform"

module VagrantPlugins
  module HostDarwin
    class Host < Vagrant.plugin("2", :host)
      def detect?(env)
        Vagrant::Util::Platform.darwin?
      end
    end
  end
end

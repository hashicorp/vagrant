# Copyright IBM Corp. 2010, 2025
# SPDX-License-Identifier: BUSL-1.1

require "vagrant"
require 'vagrant/util/platform'

module VagrantPlugins
  module HostFreeBSD
    class Host < Vagrant.plugin("2", :host)
      def detect?(env)
        Vagrant::Util::Platform.freebsd?
      end
    end
  end
end

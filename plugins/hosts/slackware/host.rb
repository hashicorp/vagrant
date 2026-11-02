# Copyright IBM Corp. 2010, 2025
# SPDX-License-Identifier: MIT

require "vagrant"

module VagrantPlugins
  module HostSlackware
    class Host < Vagrant.plugin("2", :host)
      def detect?(env)
        return File.exist?("/etc/slackware-version") ||
          !Dir.glob("/usr/lib/setup/Plamo-*").empty?
      end
    end
  end
end

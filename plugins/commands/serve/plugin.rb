# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require "vagrant"

module VagrantPlugins
  module CommandServe
    class Plugin < Vagrant.plugin("2")
      name "start Vagrant server"
      description <<-DESC
      Start Vagrant in server mode
      DESC

      command("serve") do
        require File.expand_path("../command", __FILE__)
        Command
      end
    end
  end
end

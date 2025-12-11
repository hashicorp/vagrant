# Copyright IBM Corp. 2010, 2025
# SPDX-License-Identifier: BUSL-1.1

require "vagrant"

module VagrantPlugins
  module CommandCap
    class Plugin < Vagrant.plugin("2")
      name "cap command"
      description <<-DESC
      The `cap` command checks and executes arbitrary capabilities.
      DESC

      command("cap", primary: false) do
        require_relative "command"
        Command
      end
    end
  end
end

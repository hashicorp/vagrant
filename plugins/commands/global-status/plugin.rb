require "vagrant"

module VagrantPlugins
  module CommandGlobalStatus
    class Plugin < Vagrant.plugin("2")
      name "global-status command"
      description <<-DESC
      The `global-status` command shows what the running state (running/saved/..)
      is of all the Vagrant environments known to the system.
      DESC

      command("global-status") do
        require File.expand_path("../command", __FILE__)
        Command
      end
    end
  end
end

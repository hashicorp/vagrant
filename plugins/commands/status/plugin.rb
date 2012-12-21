require "vagrant"

module VagrantPlugins
  module CommandStatus
    class Plugin < Vagrant.plugin("2")
      name "status command"
      description <<-DESC
      The `status` command shows what the running state (running/saved/..)
      is of all your virtual machines in this environment.
      DESC

      command("status") do
        require File.expand_path("../command", __FILE__)
        Command
      end
    end
  end
end

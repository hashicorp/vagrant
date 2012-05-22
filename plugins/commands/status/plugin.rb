require "vagrant"

module VagrantPlugins
  module CommandStatus
    class Plugin < Vagrant.plugin("1")
      name "status command"
      description <<-DESC
      The `status` command shows the status of all your virtual machines
      in this environment.
      DESC

      activated do
        require File.expand_path("../command", __FILE__)
      end

      command("status") { Command }
    end
  end
end

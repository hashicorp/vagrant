require "vagrant"

module VagrantPlugins
  module CommandSSH
    class Plugin < Vagrant.plugin("2")
      name "ssh command"
      description <<-DESC
      The `ssh` command allows you to SSH in to your running virtual machine.
      DESC

      command("ssh") do
        require File.expand_path("../command", __FILE__)
        Command
      end
    end
  end
end

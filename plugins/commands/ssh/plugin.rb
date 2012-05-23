require "vagrant"

module VagrantPlugins
  module CommandSSH
    class Plugin < Vagrant.plugin("1")
      name "ssh command"
      description <<-DESC
      The `ssh` command provides SSH access to the virtual machine.
      DESC

      command("ssh") do
        require File.expand_path("../command", __FILE__)
        Command
      end
    end
  end
end

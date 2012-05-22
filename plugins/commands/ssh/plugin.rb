require "vagrant"

module VagrantPlugins
  module CommandSSH
    class Plugin < Vagrant.plugin("1")
      name "ssh command"
      description <<-DESC
      The `ssh` command provides SSH access to the virtual machine.
      DESC

      activated do
        require File.expand_path("../command", __FILE__)
      end

      command("ssh") { Command }
    end
  end
end

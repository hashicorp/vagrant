require "vagrant"

module VagrantPlugins
  module CommandSSH
    autoload :Command, File.expand_path("../command", __FILE__)

    class Plugin < Vagrant.plugin("1")
      name "ssh command"
      description <<-DESC
      The `ssh` command provides SSH access to the virtual machine.
      DESC

      command("ssh") { Command }
    end
  end
end

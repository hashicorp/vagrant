require "vagrant"

module VagrantPlugins
  module CommandSSHConfig
    autoload :Command, File.expand_path("../command", __FILE__)

    class Plugin < Vagrant.plugin("1")
      name "ssh-config command"
      description <<-DESC
      The `ssh-config` command dumps an OpenSSH compatible configuration
      that can be used to quickly SSH into your virtual machine.
      DESC

      command("ssh-config") { Command }
    end
  end
end

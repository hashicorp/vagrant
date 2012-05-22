require "vagrant"

module VagrantPlugins
  module CommandSSHConfig
    class Plugin < Vagrant.plugin("1")
      name "ssh-config command"
      description <<-DESC
      The `ssh-config` command dumps an OpenSSH compatible configuration
      that can be used to quickly SSH into your virtual machine.
      DESC

      activated do
        require File.expand_path("../command", __FILE__)
      end

      command("ssh-config") { Command }
    end
  end
end

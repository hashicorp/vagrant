require "vagrant"

module VagrantPlugins
  module CommandWinRM
    class Plugin < Vagrant.plugin("2")
      name "winrm command"
      description <<-DESC
      The `winrm` command executes commands on a machine via WinRM
      DESC

      command("winrm") do
        require File.expand_path("../command", __FILE__)
        Command
      end
    end
  end
end

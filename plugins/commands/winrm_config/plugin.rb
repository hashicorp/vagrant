require "vagrant"

module VagrantPlugins
  module CommandWinRMConfig
    class Plugin < Vagrant.plugin("2")
      name "winrm-config command"
      description <<-DESC
      The `winrm-config` command dumps WinRM configuration information
      DESC

      command("winrm-config") do
        require File.expand_path("../command", __FILE__)
        Command
      end
    end
  end
end

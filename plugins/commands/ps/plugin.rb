require "vagrant"

module VagrantPlugins
  module CommandPS
    autoload :Errors, File.expand_path("../errors", __FILE__)

    class Plugin < Vagrant.plugin("2")
      name "ps command"
      description <<-DESC
      The ps command opens a remote powershell session to the
      machine if it supports powershell remoting.
      DESC

      command("ps") do
        require File.expand_path("../command", __FILE__)
        Command
      end

    end
  end
end

require "vagrant"

module VagrantPlugins
  module CommandHelp
    class Plugin < Vagrant.plugin("2")
      name "help command"
      description <<-DESC
      The `help` command shows help for the given command.
      DESC

      command("help") do
        require File.expand_path("../command", __FILE__)
        Command
      end
    end
  end
end

require "vagrant"

module VagrantPlugins
  module CommandListCommands
    class Plugin < Vagrant.plugin("2")
      name "list-commands command"
      description <<-DESC
      The `list-commands` command will list all commands that Vagrant
      understands, even hidden ones.
      DESC

      command("list-commands", primary: false) do
        require_relative "command"
        Command
      end
    end
  end
end

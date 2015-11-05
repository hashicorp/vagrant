require "vagrant"

module VagrantPlugins
  module CommandProvider
    class Plugin < Vagrant.plugin("2")
      name "provider command"
      description <<-DESC
      The `provider` command is used to interact with the various providers
      that are installed with Vagrant.
      DESC

      command("provider", primary: false) do
        require_relative "command"
        Command
      end
    end
  end
end

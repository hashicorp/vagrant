require "vagrant"

module VagrantPlugins
  module CommandReload
    class Plugin < Vagrant.plugin("2")
      name "reload command"
      description <<-DESC
      The `reload` command will halt, reconfigure your machine based on
      the Vagrantfile, and bring it back up.
      DESC

      command("reload") do
        require File.expand_path("../command", __FILE__)
        Command
      end
    end
  end
end

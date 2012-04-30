require "vagrant"

module VagrantPlugins
  module CommandReload
    autoload :Command, File.expand_path("../command", __FILE__)

    class Plugin < Vagrant.plugin("1")
      name "reload command"
      description <<-DESC
      The `reload` command will halt, reconfigure your machine based on
      the Vagrantfile, and bring it back up.
      DESC

      command("reload") { Command }
    end
  end
end

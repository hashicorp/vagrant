require "vagrant"

module VagrantPlugins
  module CommandDestroy
    autoload :Command, File.expand_path("../command", __FILE__)

    class Plugin < Vagrant.plugin("1")
      name "destroy command"
      description "The `destroy` command destroys your virtual machines."

      command("destroy") { Command }
    end
  end
end

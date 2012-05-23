require "vagrant"

module VagrantPlugins
  module CommandDestroy
    class Plugin < Vagrant.plugin("1")
      name "destroy command"
      description "The `destroy` command destroys your virtual machines."

      command("destroy") do
        require File.expand_path("../command", __FILE__)
        Command
      end
    end
  end
end

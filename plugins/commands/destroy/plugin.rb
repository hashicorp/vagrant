require "vagrant"

module VagrantPlugins
  module CommandDestroy
    class Plugin < Vagrant.plugin("2")
      name "destroy command"
      description <<-DESC
      The `destroy` command deletes and removes the files and record of your virtual machines.
      All data is lost and a new VM will have to be created using `up`
      DESC

      command("destroy") do
        require File.expand_path("../command", __FILE__)
        Command
      end
    end
  end
end

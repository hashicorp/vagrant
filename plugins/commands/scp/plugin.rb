require "vagrant"

module VagrantPlugins
  module CommandSCP
    class Plugin < Vagrant.plugin("2")
      name "scp command"
      description <<-DESC
      The `scp` command allows you to copy files from/to your running virtual machine.
      DESC

      command("scp") do
        require File.expand_path("../command", __FILE__)
        Command
      end
    end
  end
end


require "vagrant"

module VagrantPlugins
  module CommandHalt
    class Plugin < Vagrant.plugin("2")
      name "halt command"
      description <<-DESC
      The `halt` command shuts your virtual machine down forcefully.
      The command `up` recreates it.
      DESC

      command("halt") do
        require File.expand_path("../command", __FILE__)
        Command
      end
    end
  end
end

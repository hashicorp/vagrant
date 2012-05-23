require "vagrant"

module VagrantPlugins
  module CommandHalt
    class Plugin < Vagrant.plugin("1")
      name "halt command"
      description <<-DESC
      The `halt` command halts your virtual machine.
      DESC

      command("halt") do
        require File.expand_path("../command", __FILE__)
        Command
      end
    end
  end
end

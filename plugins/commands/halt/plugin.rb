require "vagrant"

module VagrantPlugins
  module CommandHalt
    class Plugin < Vagrant.plugin("1")
      name "halt command"
      description <<-DESC
      The `halt` command halts your virtual machine.
      DESC

      activated do
        require File.expand_path("../command", __FILE__)
      end

      command("halt") { Command }
    end
  end
end

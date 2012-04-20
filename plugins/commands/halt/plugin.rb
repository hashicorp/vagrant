require "vagrant"

module VagrantPlugins
  module CommandHalt
    autoload :Command, File.expand_path("../command", __FILE__)

    class Plugin < Vagrant.plugin("1")
      name "halt command"
      description <<-DESC
      The `halt` command halts your virtual machine.
      DESC

      command("halt") { Command }
    end
  end
end

require "vagrant"

module VagrantPlugins
  module CommandPort
    class Plugin < Vagrant.plugin("2")
      name "port command"
      description <<-DESC
      The `port` command displays guest port mappings.
      DESC

      command("port") do
        require File.expand_path("../command", __FILE__)
        Command
      end
    end
  end
end

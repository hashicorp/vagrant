require "vagrant"

module VagrantPlugins
  module CommandVersion
    class Plugin < Vagrant.plugin("2")
      name "version command"
      description <<-DESC
      The `version` command prints the currently installed version
      as well as the latest available version.
      DESC

      command("version") do
        require File.expand_path("../command", __FILE__)
        Command
      end
    end
  end
end

require "vagrant"

module VagrantPlugins
  module CommandPackage
    class Plugin < Vagrant.plugin("2")
      name "package command"
      description <<-DESC
      The `package` command will take a previously existing Vagrant
      environment and package it into a box file.
      DESC

      command("package") do
        require File.expand_path("../command", __FILE__)
        Command
      end
    end
  end
end

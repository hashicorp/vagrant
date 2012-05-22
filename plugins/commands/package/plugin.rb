require "vagrant"

module VagrantPlugins
  module CommandPackage
    class Plugin < Vagrant.plugin("1")
      name "package command"
      description <<-DESC
      The `package` command will take a previously existing Vagrant
      environment and package it into a box file.
      DESC

      activated do
        require File.expand_path("../command", __FILE__)
      end

      command("package") { Command }
    end
  end
end

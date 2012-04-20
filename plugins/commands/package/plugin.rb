require "vagrant"

module VagrantPlugins
  module CommandPackage
    autoload :Command, File.expand_path("../command", __FILE__)

    class Plugin < Vagrant.plugin("1")
      name "package command"
      description <<-DESC
      The `package` command will take a previously existing Vagrant
      environment and package it into a box file.
      DESC

      command("package") { Command }
    end
  end
end

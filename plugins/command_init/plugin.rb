require "vagrant"

module VagrantPlugins
  module CommandInit
    autoload :Command, File.expand_path("../command", __FILE__)

    class Plugin < Vagrant.plugin("1")
      name "init command"
      description <<-DESC
      The `init` command sets up your working directory to be a
      Vagrant-managed environment.
      DESC

      command("init") { Command }
    end
  end
end

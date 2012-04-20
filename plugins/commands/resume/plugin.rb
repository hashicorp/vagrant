require "vagrant"

module VagrantPlugins
  module CommandResume
    autoload :Command, File.expand_path("../command", __FILE__)

    class Plugin < Vagrant.plugin("1")
      name "resume command"
      description <<-DESC
      The `resume` command resumes a suspend virtual machine.
      DESC

      command("resume") { Command }
    end
  end
end

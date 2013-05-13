require "vagrant"

module VagrantPlugins
  module CommandResume
    class Plugin < Vagrant.plugin("2")
      name "resume command"
      description <<-DESC
      The `resume` command resumes a suspend virtual machine.
      DESC

      command("resume") do
        require File.expand_path("../command", __FILE__)
        Command
      end
    end
  end
end

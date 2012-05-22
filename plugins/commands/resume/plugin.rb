require "vagrant"

module VagrantPlugins
  module CommandResume
    class Plugin < Vagrant.plugin("1")
      name "resume command"
      description <<-DESC
      The `resume` command resumes a suspend virtual machine.
      DESC

      activated do
        require File.expand_path("../command", __FILE__)
      end

      command("resume") { Command }
    end
  end
end

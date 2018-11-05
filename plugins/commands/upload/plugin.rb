require "vagrant"

module VagrantPlugins
  module CommandUpload
    class Plugin < Vagrant.plugin("2")
      name "upload command"
      description <<-DESC
      The `upload` command uploads files to guest via communicator
      DESC

      command("upload") do
        require File.expand_path("../command", __FILE__)
        Command
      end
    end
  end
end

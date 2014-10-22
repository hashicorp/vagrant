require "vagrant"

module VagrantPlugins
  module FileDeploy
    class Plugin < Vagrant.plugin("2")
      name "file"
      description <<-DESC
      Deploy by pushing to a filepath on your local system or a remote share
      attached to this system
      DESC

      config(:file, :push) do
        require File.expand_path("../config", __FILE__)
        Config
      end

      push(:file) do
        require File.expand_path("../push", __FILE__)
        Push
      end
    end
  end
end

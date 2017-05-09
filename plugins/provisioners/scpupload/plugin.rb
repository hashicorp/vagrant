require "vagrant"

module VagrantPlugins
  module SCPupload
    class Plugin < Vagrant.plugin("2")
      name "scpupload"
      description <<-DESC
      Provides support for provisioning your virtual machines with
      SCP uploaded files.
      DESC

      config(:scpupload, :provisioner) do
        require File.expand_path("../config", __FILE__)
        Config
      end

      provisioner(:scpupload) do
        require File.expand_path("../provisioner", __FILE__)
        Provisioner
      end
    end
  end
end

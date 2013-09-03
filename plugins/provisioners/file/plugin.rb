require "vagrant"

module VagrantPlugins
  module FileUpload
    class Plugin < Vagrant.plugin("2")
      name "file"
      description <<-DESC
      Provides support for provisioning your virtual machines with
      uploaded files.
      DESC

      config(:file, :provisioner) do
        require File.expand_path("../config", __FILE__)
        Config
      end

      provisioner(:file) do
        require File.expand_path("../provisioner", __FILE__)
        Provisioner
      end
    end
  end
end

require "vagrant"

module VagrantPlugins
  module Kernel_V1
    # This is the "kernel" of Vagrant and contains the configuration classes
    # that make up the core of Vagrant.
    class Plugin < Vagrant.plugin("1")
      name "kernel"
      description <<-DESC
      The kernel of Vagrant. This plugin contains required items for even
      basic functionality of Vagrant version 1.
      DESC

      # Core configuration keys provided by the kernel. Note that all
      # the kernel configuration classes are marked as _upgrade safe_ (the
      # true 2nd param). This means that these can be loaded in ANY version
      # of the core of Vagrant.
      config("ssh", true) do
        require File.expand_path("../config/ssh", __FILE__)
        SSHConfig
      end

      config("nfs", true) do
        require File.expand_path("../config/nfs", __FILE__)
        NFSConfig
      end

      config("package", true) do
        require File.expand_path("../config/package", __FILE__)
        PackageConfig
      end

      config("vagrant", true) do
        require File.expand_path("../config/vagrant", __FILE__)
        VagrantConfig
      end

      config("vm", true) do
        require File.expand_path("../config/vm", __FILE__)
        VMConfig
      end
    end
  end
end

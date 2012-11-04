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

      # Core configuration keys provided by the kernel.
      config("ssh") do
        require File.expand_path("../config/ssh", __FILE__)
        SSHConfig
      end

      config("nfs") do
        require File.expand_path("../config/nfs", __FILE__)
        NFSConfig
      end

      config("package") do
        require File.expand_path("../config/package", __FILE__)
        PackageConfig
      end

      config("vagrant") do
        require File.expand_path("../config/vagrant", __FILE__)
        VagrantConfig
      end

      config("vm") do
        require File.expand_path("../config/vm", __FILE__)
        VMConfig
      end
    end
  end
end

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

      activated do
        require File.expand_path("../config/ssh", __FILE__)
        require File.expand_path("../config/nfs", __FILE__)
        require File.expand_path("../config/package", __FILE__)
        require File.expand_path("../config/vagrant", __FILE__)
        require File.expand_path("../config/vm", __FILE__)
      end

      # Core configuration keys provided by the kernel.
      config("ssh")     { SSHConfig }
      config("nfs")     { NFSConfig }
      config("package") { PackageConfig }
      config("vagrant") { VagrantConfig }
      config("vm")      { VMConfig }
    end
  end
end

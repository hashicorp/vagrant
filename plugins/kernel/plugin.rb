require "vagrant"

module VagrantPlugins
  module Kernel
    autoload :SSHConfig,     File.expand_path("../config/ssh", __FILE__)
    autoload :NFSConfig,     File.expand_path("../config/nfs", __FILE__)
    autoload :PackageConfig, File.expand_path("../config/package", __FILE__)
    autoload :VagrantConfig, File.expand_path("../config/vagrant", __FILE__)
    autoload :VMConfig,      File.expand_path("../config/vm", __FILE__)

    # This is the "kernel" of Vagrant and contains the configuration classes
    # that make up the core of Vagrant.
    class Plugin < Vagrant.plugin("1")
      name "kernel"
      description <<-DESC
      The kernel of Vagrant. This plugin contains required items for even
      basic functionality of Vagrant version 1.
      DESC

      # Core configuration keys provided by the kernel.
      config("ssh")     { SSHConfig }
      config("nfs")     { NFSConfig }
      config("package") { PackageConfig }
      config("vagrant") { VagrantConfig }
      config("vm")      { VMConfig }
    end
  end
end

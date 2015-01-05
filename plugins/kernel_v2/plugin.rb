require "vagrant"

module VagrantPlugins
  module Kernel_V2
    # This is the "kernel" of Vagrant and contains the configuration classes
    # that make up the core of Vagrant for V2.
    class Plugin < Vagrant.plugin("2")
      name "kernel"
      description <<-DESC
      The kernel of Vagrant. This plugin contains required items for even
      basic functionality of Vagrant version 2.
      DESC

      # Core configuration keys provided by the kernel. Note that unlike
      # "kernel_v1", none of these configuration classes are upgradable.
      # This is by design, since we can't be sure if they're upgradable
      # until another version is available.
      config("ssh") do
        require File.expand_path("../config/ssh", __FILE__)
        SSHConfig
      end

      config("package") do
        require File.expand_path("../config/package", __FILE__)
        PackageConfig
      end

      config("push") do
        require File.expand_path("../config/push", __FILE__)
        PushConfig
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

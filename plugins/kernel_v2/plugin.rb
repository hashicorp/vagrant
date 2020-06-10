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

      plugins = Vagrant::Plugin::Manager.instance.installed_plugins
      if !plugins.keys.include?("vagrant-triggers")
        config("trigger") do
          require File.expand_path("../config/trigger", __FILE__)
          TriggerConfig
        end
      else
        if !ENV["VAGRANT_USE_VAGRANT_TRIGGERS"]
        $stderr.puts <<-EOF
WARNING: Vagrant has detected the `vagrant-triggers` plugin. This plugin conflicts
with the internal triggers implementation. Please uninstall the `vagrant-triggers`
plugin and run the command again if you wish to use the core trigger feature. To
uninstall the plugin, run the command shown below:

  vagrant plugin uninstall vagrant-triggers

Note that the community plugin `vagrant-triggers` and the core trigger feature
in Vagrant do not have compatible syntax.

To disable this warning, set the environment variable `VAGRANT_USE_VAGRANT_TRIGGERS`.
EOF
        end
      end
    end
  end
end

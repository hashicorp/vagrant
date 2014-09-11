require "vagrant"

module VagrantPlugins
  module CFEngine
    class Plugin < Vagrant.plugin("2")
      name "CFEngine Provisioner"
      description <<-DESC
      Provisions machines with CFEngine.
      DESC

      config(:cfengine, :provisioner) do
        require_relative "config"
        Config
      end

      guest_capability("debian", "cfengine_install") do
        require_relative "cap/debian/cfengine_install"
        Cap::Debian::CFEngineInstall
      end

      guest_capability("linux", "cfengine_needs_bootstrap") do
        require_relative "cap/linux/cfengine_needs_bootstrap"
        Cap::Linux::CFEngineNeedsBootstrap
      end

      guest_capability("linux", "cfengine_installed") do
        require_relative "cap/linux/cfengine_installed"
        Cap::Linux::CFEngineInstalled
      end

      guest_capability("redhat", "cfengine_install") do
        require_relative "cap/redhat/cfengine_install"
        Cap::RedHat::CFEngineInstall
      end

      guest_capability("suse", "cfengine_install") do
        require_relative "cap/suse/cfengine_install"
        Cap::SUSE::CFEngineInstall
      end

      provisioner(:cfengine) do
        require_relative "provisioner"
        Provisioner
      end
    end
  end
end

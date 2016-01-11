require "vagrant"

module VagrantPlugins
  module HostDarwin
    class Plugin < Vagrant.plugin("2")
      name "Mac OS X host"
      description "Mac OS X host support."

      host("darwin", "bsd") do
        require_relative "host"
        Host
      end

      host_capability("darwin", "provider_install_virtualbox") do
        require_relative "cap/provider_install_virtualbox"
        Cap::ProviderInstallVirtualBox
      end

      host_capability("darwin", "rdp_client") do
        require_relative "cap/rdp"
        Cap::RDP
      end
    end
  end
end

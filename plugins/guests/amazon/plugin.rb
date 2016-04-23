require "vagrant"

module VagrantPlugins
  module GuestRedHat
    class Plugin < Vagrant.plugin("2")
      name "Amazon Linux AMI"
      description "Amazon Linux AMI Support."

      guest("redhat", "linux") do
        require File.expand_path("../guest", __FILE__)
        Guest
      end

      guest_capability("redhat", "change_host_name") do
        require_relative "../redhat/cap/change_host_name"
        ::VagrantPlugins::GuestRedHat::Cap::ChangeHostName
      end

      guest_capability("redhat", "configure_networks") do
        require_relative "../redhat/cap/configure_networks"
        ::VagrantPlugins::GuestRedHat::Cap::ConfigureNetworks
      end

      guest_capability("amazon", "flavor") do
        require_relative "cap/flavor"
        Cap::Flavor
      end

      guest_capability("redhat", "network_scripts_dir") do
        require_relative "../redhat/cap/network_scripts_dir"
        ::VagrantPlugins::GuestRedHat::Cap::NetworkScriptsDir
      end

      guest_capability("redhat", "nfs_client_install") do
        require_relative "../redhat/cap/nfs_client"
        ::VagrantPlugins::GuestRedHat::Cap::NFSClient
      end

      guest_capability("redhat", "nfs_client_installed") do
        require_relative "../redhat/cap/nfs_client"
        ::VagrantPlugins::GuestRedHat::Cap::NFSClient
      end

      guest_capability("redhat", "rsync_install") do
        require_relative "../redhat/cap/rsync"
        ::VagrantPlugins::GuestRedHat::Cap::RSync
      end

      def self.dnf?(machine)
        machine.communicate.test("/usr/bin/which -s dnf")
      end

    end
  end
end

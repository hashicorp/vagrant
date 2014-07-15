require 'vagrant'

module VagrantPlugins
  module GuestEnterpriseLinux7

    class Plugin < Vagrant.plugin("2")
      name "Enterprise Linux 7 Guest"
      description "Enterprise Linux 7 guest support."

      guest("el7", "redhat") do
        require File.expand_path("../guest", __FILE__)
        Guest
      end

      guest_capability("el7","configure_networks") do
        require File.expand_path("../../fedora/cap/configure_networks", __FILE__)
        ::VagrantPlugins::GuestFedora::Cap::ConfigureNetworks
      end

    end
  end
end

require 'tempfile'
require 'vagrant/util/template_renderer'

module VagrantPlugins
  module GuestPhoton
    module Cap
      class ConfigureNetworks
        include Vagrant::Util

        def self.configure_networks(machine, networks)
          machine.communicate.tap do |comm|
            # Read network interface names
            interfaces = []
            comm.sudo("ifconfig | grep 'eth' | cut -f1 -d' '") do |_, result|
              interfaces = result.split("\n")
            end

            # Configure interfaces
            networks.each do |network|
              comm.sudo("ifconfig #{interfaces[network[:interface].to_i]} #{network[:ip]} netmask #{network[:netmask]}")
            end
          end
        end
      end
    end
  end
end

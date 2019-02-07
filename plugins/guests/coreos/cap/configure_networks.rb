require "tempfile"

require_relative "../../../../lib/vagrant/util/template_renderer"

module VagrantPlugins
  module GuestCoreOS
    module Cap
      class ConfigureNetworks
        include Vagrant::Util

        def self.configure_networks(machine, networks)
          machine.communicate.tap do |comm|
            # Read network interface names
            interfaces = []
            comm.sudo("ifconfig | grep -E '(e[n,t][h,s,p][[:digit:]]([a-z][[:digit:]])?)' | cut -f1 -d:") do |_, result|
              interfaces = result.split("\n")
            end

            # Build a list of commands
            commands = []

            # Stop default systemd
            #commands << "systemctl stop etcd"

            # Configure interfaces
            # FIXME: fix matching of interfaces with IP addresses
            networks.each do |network|
              iface = interfaces[network[:interface].to_i]
              commands << "ifconfig #{iface} #{network[:ip]} netmask #{network[:netmask]}".squeeze(" ")
            end


            # Run all network configuration commands in one communicator session.
            comm.sudo(commands.join("\n"))
          end
        end

        private

        def self.get_ip(machine)
          ip = nil
          machine.config.vm.networks.each do |type, opts|
            if type == :private_network && opts[:ip]
              ip = opts[:ip]
              break
            end
          end

          ip
        end
      end
    end
  end
end

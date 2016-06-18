module VagrantPlugins
  module GuestPhoton
    module Cap
      class ConfigureNetworks
        include Vagrant::Util

        def self.configure_networks(machine, networks)
          comm = machine.communicate

          commands   = ["set -e"]
          interfaces = []

          comm.sudo("ifconfig | grep 'eth' | cut -f1 -d' '") do |_, result|
            interfaces = result.split("\n")
          end

          networks.each do |network|
            device = interfaces[network[:interface]]
            command =  "ifconfig #{device}"
            command << " #{network[:ip]}" if network[:ip]
            command << " netmast #{network[:netmask]}" if network[:netmask]
            commands << command
          end

          comm.sudo(commands.join("\n"))
        end
      end
    end
  end
end

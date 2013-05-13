module VagrantPlugins
  module GuestSolaris
    module Cap
      class ConfigureNetworks
        def self.configure_networks(machine, networks)
          networks.each do |network|
            device = "#{machine.config.solaris.device}#{network[:interface]}"
            su_cmd = machine.config.solaris.suexec_cmd
            ifconfig_cmd = "#{su_cmd} /sbin/ifconfig #{device}"

            machine.communicate.execute("#{ifconfig_cmd} plumb")

            if network[:type].to_sym == :static
              machine.communicate.execute("#{ifconfig_cmd} inet #{network[:ip]} netmask #{network[:netmask]}")
              machine.communicate.execute("#{ifconfig_cmd} up")
              machine.communicate.execute("#{su_cmd} sh -c \"echo '#{network[:ip]}' > /etc/hostname.#{device}\"")
            elsif network[:type].to_sym == :dhcp
              machine.communicate.execute("#{ifconfig_cmd} dhcp start")
            end
          end
        end
      end
    end
  end
end

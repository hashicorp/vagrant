module VagrantPlugins
  module GuestEsxi
    module Cap
      class ConfigureNetworks
        def self.configure_networks(machine, networks)
          networks.each do |network|
            ix = network[:interface]
            switch = "vSwitch#{ix}"
            pg = "VagrantNetwork#{ix}"
            vmnic = "vmnic#{ix}"
            device = "vmk#{ix}"

            if machine.communicate.test("localcli network ip interface ipv4 get -i #{device}")
              machine.communicate.execute("localcli network ip interface remove -i #{device}")
            end

            if machine.communicate.test("localcli network vswitch standard list -v #{switch}")
              machine.communicate.execute("localcli network vswitch standard remove -v #{switch}")
            end

            machine.communicate.execute("localcli network vswitch standard add -v #{switch}")
            machine.communicate.execute("localcli network vswitch standard uplink add -v #{switch} -u #{vmnic}")
            machine.communicate.execute("localcli network vswitch standard portgroup add -v #{switch} -p #{pg}")
            machine.communicate.execute("localcli network ip interface add -i #{device} -p #{pg}")

            ifconfig = "localcli network ip interface ipv4 set -i #{device}"

            if network[:type].to_sym == :static
              machine.communicate.execute("#{ifconfig} -t static --ipv4 #{network[:ip]} --netmask #{network[:netmask]}")
            elsif network[:type].to_sym == :dhcp
              machine.communicate.execute("#{ifconfig} -t dhcp")
            end
          end
        end
      end
    end
  end
end

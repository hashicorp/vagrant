# A general Vagrant system implementation for "solaris 11".
#
# Contributed by Jan Thomas Moldung <janth@moldung.no>

module VagrantPlugins
  module GuestSolaris11
    module Cap
      class ConfigureNetworks
        def self.configure_networks(machine, networks)
          networks.each do |network|
            device = "#{machine.config.solaris11.device}#{network[:interface]}"
            su_cmd = machine.config.solaris11.suexec_cmd
            mask = "#{network[:netmask]}"
            cidr = mask.split(".").map { |e| e.to_i.to_s(2).rjust(8, "0") }.join.count("1").to_s

            if network[:type].to_sym == :static
              if machine.communicate.test("ipadm | grep #{device}/v4")
                machine.communicate.execute("#{su_cmd} ipadm delete-addr #{device}/v4")
              end
              machine.communicate.execute("#{su_cmd} ipadm create-addr -T static -a #{network[:ip]}/#{cidr} #{device}/v4")
            elsif network[:type].to_sym == :dhcp
              if machine.communicate.test("ipadm show-if -o all | grep #{device} | tr -s ' ' | cut -d ' ' -f 6  | grep '4\|6'")
                machine.communicate.execute("#{su_cmd} ipadm create-addr -T addrconf #{device}/v4")
              end
            end
          end
        end
      end
    end
  end
end

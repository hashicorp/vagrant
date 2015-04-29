module VagrantPlugins
  module GuestWindows
    module Cap
      module ChooseAddressableIPAddr
        def self.choose_addressable_ip_addr(machine, possible)
          possible_ips = possible

          info = machine.ssh_info
          host_ip = IPAddr.new(info[:host])
          possible_ips = possible.map{ |ip| IPAddr.new(ip)}
          possible_ips = possible_ips.sort_by{|ip| (host_ip.to_i - ip.to_i).abs}

          machine.communicate.tap do |comm|
            possible_ips.each do |ip|
              command = "ping -n 1 -w 1 #{ip}"
              if comm.test(command)
                return ip
              end
            end
          end

          nil
        end
      end
    end
  end
end

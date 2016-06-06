module VagrantPlugins
  module GuestLinux
    module Cap
      module ChooseAddressableIPAddr
        def self.choose_addressable_ip_addr(machine, possible)
          comm = machine.communicate

          possible.each do |ip|
            command = "ping -c1 -w1 -W1 #{ip}"
            if comm.test(command)
              return ip
            end
          end

          nil
        end
      end
    end
  end
end

module VagrantPlugins
  module GuestLinux
    module Cap
      module ChooseAddressableIPAddr
        def self.choose_addressable_ip_addr(machine, possible)
          comm = machine.communicate

          possible.each do |ip|
            if comm.test("ping -c1 -w1 -W1 #{ip}")
              return ip
            end
          end

          return nil
        end
      end
    end
  end
end

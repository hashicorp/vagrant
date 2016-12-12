module VagrantPlugins
  module GuestDarwin
    module Cap
      module ChooseAddressableIPAddr
        def self.choose_addressable_ip_addr(machine, possible)
          comm = machine.communicate

          possible.each do |ip|
            if comm.test("ping -c1 -t1 #{ip}")
              return ip
            end
          end

          # If we got this far, there are no addressable IPs
          return nil
        end
      end
    end
  end
end

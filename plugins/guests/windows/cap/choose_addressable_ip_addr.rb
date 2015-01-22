module VagrantPlugins
  module GuestWindows
    module Cap
      module ChooseAddressableIPAddr
        def self.choose_addressable_ip_addr(machine, possible)
          machine.communicate.tap do |comm|
            possible.each do |ip|
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

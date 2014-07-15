module VagrantPlugins
  module GuestWindows
    module Cap
      module ChooseAddressableIPAddr
        def self.choose_addressable_ip_addr(machine, possible)
          machine.communicate.tap do |comm|
            possible.each do |ip|
              return ip
            end
          end

          nil
        end
      end
    end
  end
end

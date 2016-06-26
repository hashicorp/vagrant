module VagrantPlugins
  module GuestLinux
    module Cap
      class NetworkInterfaces
        # Get network interfaces as a list. The result will be something like:
        #
        #   eth0\nenp0s8\nenp0s9
        #
        # @return [Array<String>]
        def self.network_interfaces(machine, path = "/sbin/ip")
          s = ""
          machine.communicate.sudo("#{path} -o -0 addr | grep -v LOOPBACK | awk '{print $2}' | sed 's/://'") do |type, data|
            s << data if type == :stdout
          end
          s.split("\n")
        end
      end
    end
  end
end

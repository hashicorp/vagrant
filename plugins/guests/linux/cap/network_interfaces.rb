module VagrantPlugins
  module GuestLinux
    module Cap
      class NetworkInterfaces
        @@logger = Log4r::Logger.new("vagrant::guest::linux::network_interfaces")

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
          ifaces = s.split("\n")
          @@logger.debug("Unsorted list: #{ifaces.inspect}")
          # Break out integers from strings and sort the arrays to provide
          # a natural sort for the interface names
          ifaces = ifaces.map do |iface|
            iface.scan(/(.+?)(\d+)/).flatten.map do |iface_part|
              if iface_part.to_i.to_s == iface_part
                iface_part.to_i
              else
                iface_part
              end
            end
          end.sort.map(&:join)
          @@logger.debug("Sorted list: #{ifaces.inspect}")
          ifaces
        end
      end
    end
  end
end

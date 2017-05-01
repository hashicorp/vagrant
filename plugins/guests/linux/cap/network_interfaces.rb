module VagrantPlugins
  module GuestLinux
    module Cap
      class NetworkInterfaces
        # Valid ethernet device prefix values.
        # eth - classic prefix
        # en  - predictable interface names prefix
        POSSIBLE_ETHERNET_PREFIXES = ["eth".freeze, "en".freeze].freeze

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
          # In some cases net devices may be added to the guest and will not
          # properly show up when using `ip`. This pulls any device information
          # that can be found in /proc and adds it to the list of interfaces
          s << "\n"
          machine.communicate.sudo("cat /proc/net/dev | grep -E '^[a-z0-9 ]+:' | awk '{print $1}' | sed 's/://'", error_check: false) do |type, data|
            s << data if type == :stdout
          end
          ifaces = s.split("\n")
          @@logger.debug("Unsorted list: #{ifaces.inspect}")
          # Break out integers from strings and sort the arrays to provide
          # a natural sort for the interface names
          # NOTE: Devices named with a hex value suffix will _not_ be sorted
          #  as expected. This is generally seen with veth* devices, and proper ordering
          #  is currently not required
          ifaces = ifaces.map do |iface|
            iface.scan(/(.+?)(\d+)/).flatten.map do |iface_part|
              if iface_part.to_i.to_s == iface_part
                iface_part.to_i
              else
                iface_part
              end
            end
          end
          ifaces = ifaces.uniq.sort do |lhs, rhs|
            result = 0
            slice_length = [rhs.size, lhs.size].min
            slice_length.times do |idx|
              if(lhs[idx].is_a?(rhs[idx].class))
                result = lhs[idx] <=> rhs[idx]
              elsif(lhs[idx].is_a?(String))
                result = 1
              else
                result = -1
              end
              break if result != 0
            end
            result
          end.map(&:join)
          @@logger.debug("Sorted list: #{ifaces.inspect}")
          # Extract ethernet devices and place at start of list
          resorted_ifaces = []
          resorted_ifaces += ifaces.find_all do |iface|
            POSSIBLE_ETHERNET_PREFIXES.any?{|prefix| iface.start_with?(prefix)} &&
              iface.match(/^[a-zA-Z0-9]+$/)
          end
          resorted_ifaces += ifaces - resorted_ifaces
          ifaces = resorted_ifaces
          @@logger.debug("Ethernet preferred sorted list: #{ifaces.inspect}")
          ifaces
        end
      end
    end
  end
end

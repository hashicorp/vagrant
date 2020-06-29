module Vagrant
  module Util
    # Helper methods for modfiying guests /etc/hosts file
    module GuestHosts

      module Unix
        DEAFAULT_LOOPBACK_CHECK_LIMIT = 5.freeze

        # Add hostname to a loopback address on /etc/hosts if not already there
        # Will insert name at the first free address of the form 127.0.X.1, up to
        # the loop_bound
        #
        # @param [Communicator] 
        # @param [String] full hostanme
        # @param [int] (option) defines the upper bound for searching for an available loopback address
        def add_hostname_to_loopback_interface(comm, name, loop_bound=DEAFAULT_LOOPBACK_CHECK_LIMIT)
          basename = name.split(".", 2)[0]
          comm.sudo <<-EOH.gsub(/^ {14}/, '')
          grep -w '#{name}' /etc/hosts || {
            for i in {1..#{loop_bound}}; do
              grep -w "127.0.${i}.1" /etc/hosts || {
                echo "127.0.${i}.1 #{name} #{basename}" >> /etc/hosts
                break
              }
            done
          }
          EOH
        end
      end

      # Linux specific inspection helpers
      module Linux
        include Unix
        # Remove any line in /etc/hosts that contains hostname,
        # then add hostname with associated ip 
        #
        # @param [Communicator] 
        # @param [String] full hostanme
        # @param [String] target ip
        def replace_host(comm, name, ip)
          basename = name.split(".", 2)[0]
          comm.sudo <<-EOH.gsub(/^ {14}/, '')
          sed -i '/#{name}/d' /etc/hosts
          sed -i'' '1i '#{ip}'\\t#{name}\\t#{basename}' /etc/hosts
          EOH
        end
      end

      # BSD specific inspection helpers
      module BSD
        include Unix
        # Remove any line in /etc/hosts that contains hostname,
        # then add hostname with associated ip 
        #
        # @param [Communicator] 
        # @param [String] full hostanme
        # @param [String] target ip
        def replace_host(comm, name, ip)
          basename = name.split(".", 2)[0]
          comm.sudo <<-EOH.gsub(/^ {14}/, '')
          sed -i.bak '/#{name}/d' /etc/hosts
          sed -i.bak '1i\\\n#{ip}\t#{name}\t#{basename}\n' /etc/hosts
          EOH
        end
      end
    end
  end
end

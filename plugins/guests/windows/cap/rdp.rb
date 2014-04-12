module VagrantPlugins
  module GuestWindows
    module Cap
      class RDP
        def self.rdp_info(machine)
          ssh_info = machine.ssh_info
          username = ssh_info[:username]
          if machine.config.vm.communicator == :winrm
            username = machine.config.winrm.username
          end

          host = ssh_info[:host]
          port = 3389

          if host == "127.0.0.1"
            # We need to find a forwarded port...
            search_port = 3389
            ports       = nil
            if machine.provider.capability?(:forwarded_ports)
              ports = machine.provider.capability(:forwarded_ports)
            else
              ports = {}.tap do |result|
                machine.config.vm.networks.each do |type, netopts|
                  next if type != :forwarded_port
                  next if !netopts[:host]
                  result[netopts[:host]] = netopts[:guest]
                end
              end
            end

            ports = ports.invert
            port  = ports[search_port]
            return nil if !port
          end

          return {
            host: host,
            port: port,
            username: username,
          }
        end
      end
    end
  end
end

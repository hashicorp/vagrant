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

          return {
            host: ssh_info[:host],
            username: username,
          }
        end
      end
    end
  end
end

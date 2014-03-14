module VagrantPlugins
  module CommunicatorWinRM
    # This is a helper module that provides some functions to the
    # communicator. This is extracted into a module so that we can
    # easily unit test these methods.
    module Helper
      # Returns the address to access WinRM. This does not contain
      # the port.
      #
      # @param [Vagrant::Machine] machine
      # @return [String]
      def self.winrm_address(machine)
        addr = machine.config.winrm.host
        return addr if addr

        ssh_info = machine.ssh_info
        raise Errors::WinRMNotReady if !ssh_info
        return ssh_info[:host]
      end

      # Returns the port to access WinRM.
      #
      # @param [Vagrant::Machine] machine
      # @return [Integer]
      def self.winrm_port(machine)
        host_port = machine.config.winrm.port
        if machine.config.winrm.guest_port
          # Search by guest port if we can. We use a provider capability
          # if we have it. Otherwise, we just scan the Vagrantfile defined
          # ports.
          port = nil
          if machine.provider.capability?(:forwarded_ports)
            machine.provider.capability(:forwarded_ports).each do |host, guest|
              if guest == machine.config.winrm.guest_port
                port = host
                break
              end
            end
          end

          if !port
            machine.config.vm.networks.each do |type, netopts|
              next if type != :forwarded_port
              next if !netopts[:host]
              if netopts[:guest] == machine.config.winrm.guest_port
                port = netopts[:host]
                break
              end
            end
          end

          # Set it if we found it
          host_port = port if port
        end

        host_port
      end
    end
  end
end

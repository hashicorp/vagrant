module VagrantPlugins
  module DockerProvider
    module Cap
      module PublicAddress
        def self.public_address(machine)
          return nil if machine.state.id != :running

          # If we're using a host VM, then return the IP of that
          # rather than of our own machine.
          if machine.provider.host_vm?
            host_machine = machine.provider.host_vm
            return nil if !host_machine.provider.capability?(:public_address)
            return host_machine.provider.capability(:public_address)
          end

          ssh_info = machine.ssh_info
          return nil if !ssh_info
          ssh_info[:host]
        end
      end
    end
  end
end

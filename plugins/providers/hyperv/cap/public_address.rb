module VagrantPlugins
  module Share
    module Cap
      class VirtualBox
        def self.public_address(machine)
          return nil if machine.state.id != :running

          ssh_info = machine.ssh_info
          return nil if !ssh_info
          ssh_info[:host]
        end
      end
    end
  end
end

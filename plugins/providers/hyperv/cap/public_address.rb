module VagrantPlugins
  module HyperV
    module Cap
      module PublicAddress
        def self.public_address(machine)
          return nil if machine.state.id != :running

          communicator_info = machine.communicator_info
          return nil if !communicator_info
          communicator_info[:host]
        end
      end
    end
  end
end

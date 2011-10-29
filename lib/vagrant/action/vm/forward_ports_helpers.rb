module Vagrant
  class Action
    module VM
      # Helper methods for forwarding ports. Requires that the environment
      # is set to the `@env` instance variable.
      module ForwardPortsHelpers
        # Returns an array of used ports. This method is implemented
        # differently depending on the VirtualBox version, but the
        # behavior is the same.
        #
        # @return [Array<String>]
        def used_ports
          result = VirtualBox::VM.all.collect do |vm|
            if vm.accessible? && vm.running? && vm.uuid != @env["vm"].uuid
              vm.network_adapters.collect do |na|
                na.nat_driver.forwarded_ports.collect do |fp|
                  fp.hostport.to_i
                end
              end
            end
          end
          result.flatten.uniq
        end
      end
    end
  end
end

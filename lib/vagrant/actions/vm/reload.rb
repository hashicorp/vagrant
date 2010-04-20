module Vagrant
  module Actions
    module VM
      class Reload < Base
        def prepare
          steps = [Customize, ForwardPorts, SharedFolders, Boot]
          steps.unshift(Halt) if @runner.vm.running?
          steps << Provision if !@runner.env.config.vm.provisioner.nil?

          steps.each do |action_klass|
            @runner.add_action(action_klass)
          end
        end

        def after_halt
          # This sleep is here to allow the VM to clean itself up. There appears
          # nothing [obvious] in the VirtualBox API to automate this. For now, this
          # is an interim solution.
          sleep 1
        end
      end
    end
  end
end
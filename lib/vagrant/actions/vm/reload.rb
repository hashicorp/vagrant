module Vagrant
  module Actions
    module VM
      class Reload < Base
        def prepare
          steps = [ForwardPorts, SharedFolders, Boot]
          steps.unshift(Halt) if @runner.vm.running?
          steps << Provision if Vagrant.config.chef.enabled

          steps.each do |action_klass|
            @runner.add_action(action_klass)
          end
        end
      end
    end
  end
end